# The Halloween Table

A party game engine for one night at home. Guests log in on their phones, the TV shows what's
happening, and the host runs it all from their own phone or laptop.

There is one building block: the **card**. A card is some text, who gets it, how they answer,
and how the answers are revealed. Pekleken, trivia, secret missions, the costume contest and
the photo hunt are all just decks of cards, made and edited in the host's pages.

| Card setting | Choices |
|---|---|
| Who gets it | Everyone, on stage · One guest, privately |
| How they answer | Point at a guest · Multiple choice · Write something · Rate 1–10 · Take a photo · Tap a button · Nothing |
| Reveal | Bar chart with voters · Only the winner · Every answer with names · Every answer, no names |
| Extras | Points, right answer, time limit |

`{guest}` in a card's text becomes a random guest's name when it's played. For a personal
card it is never the guest themselves.

When the host plays a card, it takes over every phone and the TV at once. When it's revealed,
the results appear everywhere.

## Letting people in

Anyone who can log in can knock, but nobody gets into the game until a host lets them in.
Someone new logs in, picks a name and a sigil, and waits at the door. Hosts see them at the
top of the host page (and a notice on their own phone), and can let them in or turn them
away. Guests whose email is in `HOST_EMAILS` are hosts and skip the door.

## Pages

- `/`: a guest's phone. The card on stage, their sealed personal cards, and the standings.
- `/tv`: the big screen. The card and its answers, or a QR code to join and the standings.
- `/host`: draw and reveal cards, deal personal cards, approve challenges, give points.
- `/host/decks`: make decks and cards. The first visit offers the starter decks.
- `/host/guests`: let people in, make guests hosts, or remove them.

## Development

You need Elixir 1.20 with OTP 29. There is no asset build: CSS and JS are plain files in
`priv/static/assets/`.

```sh
mix setup
mix phx.server   # http://localhost:4000
```

Without login set up, log in with `/dev/login?name=Morticia` (development only). The name
`host` logs in as a host. Use a private window per guest to play with several at once.

Real login is OpenID Connect, the same as Meridian's: with WorkOS, a first-party confidential
application under Connect, on your AuthKit domain. Copy `example.env` to `.env` and fill it
in; it's read automatically in development.

Run `mix precommit` before committing.

## Deploying

Pushes to `main` build `ghcr.io/albindalbert/halloween2026:main` (see
`.github/workflows/image.yml`). `deploy/app` is a kustomize base: one pod with a volume for the
SQLite database and guests' photos. Migrations run when the app starts.

An overlay provides a ConfigMap `halloween-config` (`PHX_HOST`, `HOST_EMAILS`, `OIDC_ISSUER`,
`OIDC_CLIENT_ID`), a Secret `halloween-secrets` (`SECRET_KEY_BASE`, `OIDC_CLIENT_SECRET`), and
an ingress. LiveView needs websockets through the ingress, and `PHX_HOST` must be the host the
guests use. Add `https://<PHX_HOST>/auth/callback` as a redirect URI on the Connect application.
