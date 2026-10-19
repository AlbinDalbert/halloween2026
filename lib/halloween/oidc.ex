defmodule Halloween.OIDC do
  @moduledoc """
  Login with an OpenID Connect provider (`OIDC_ISSUER`), the same way Meridian does it: the
  authorization code flow with PKCE, as a confidential client (`OIDC_CLIENT_ID`,
  `OIDC_CLIENT_SECRET`). With WorkOS, the issuer is the AuthKit domain and the client is a
  first-party application under Connect.

  Unlike Meridian, this doesn't verify ID tokens: the tokens come straight from the token
  endpoint over TLS, and who the guest is comes from the userinfo endpoint.
  """
  require Logger

  def configured?,
    do: Enum.all?([:issuer, :client_id, :client_secret], &(config(&1) not in [nil, ""]))

  @doc "A random URL-safe string, for `state` and the PKCE code verifier."
  def random_token, do: Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)

  def authorize_url(redirect_uri, state, verifier) do
    with {:ok, %{"authorization_endpoint" => endpoint}} <- discovery() do
      query =
        URI.encode_query(%{
          response_type: "code",
          scope: "openid email profile",
          client_id: config(:client_id),
          redirect_uri: redirect_uri,
          state: state,
          code_challenge: Base.url_encode64(:crypto.hash(:sha256, verifier), padding: false),
          code_challenge_method: "S256"
        })

      {:ok, endpoint <> "?" <> query}
    end
  end

  @doc "Exchanges the code for an access token and returns the guest: `id`, `email`, `picture`."
  def sign_in(code, redirect_uri, verifier) do
    with {:ok, %{"token_endpoint" => token_endpoint, "userinfo_endpoint" => userinfo_endpoint}} <-
           discovery(),
         {:ok, %{"access_token" => access_token}} <-
           post(token_endpoint,
             grant_type: "authorization_code",
             code: code,
             redirect_uri: redirect_uri,
             client_id: config(:client_id),
             client_secret: config(:client_secret),
             code_verifier: verifier
           ),
         {:ok, %{"sub" => sub} = info} <- get(userinfo_endpoint, access_token) do
      {:ok, %{id: sub, email: info["email"], picture: info["picture"]}}
    end
  end

  defp discovery do
    issuer = String.trim_trailing(config(:issuer), "/")
    get(issuer <> "/.well-known/openid-configuration", nil)
  end

  defp get(url, token) do
    auth = if token, do: [auth: {:bearer, token}], else: []
    url |> Req.get([retry: false] ++ auth) |> body(url)
  end

  defp post(url, form), do: url |> Req.post(form: form, retry: false) |> body(url)

  defp body({:ok, %{status: 200, body: %{} = body}}, _url), do: {:ok, body}

  defp body({:ok, %{status: status, body: body}}, url) do
    Logger.warning("OIDC request to #{url} failed: #{status} #{inspect(body)}")
    {:error, {:status, status}}
  end

  defp body({:error, error}, url) do
    Logger.warning("OIDC request to #{url} failed: #{Exception.message(error)}")
    {:error, :provider_unavailable}
  end

  defp config(key), do: Application.fetch_env!(:halloween, :oidc)[key]
end
