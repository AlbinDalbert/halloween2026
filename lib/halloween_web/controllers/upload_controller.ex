defmodule HalloweenWeb.UploadController do
  use HalloweenWeb, :controller

  def show(conn, %{"name" => name}) do
    path = Path.join(Halloween.Uploads.dir(), Path.basename(name))

    if File.regular?(path) do
      conn
      |> put_resp_content_type(MIME.from_path(path), nil)
      |> put_resp_header("cache-control", "private, max-age=86400")
      |> send_file(200, path)
    else
      send_resp(conn, 404, "Not found")
    end
  end
end
