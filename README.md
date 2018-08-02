# Tribevibe Server

## Quickstart

  * Install dependencies with `mix deps.get`
  * Copy .env.sample into .env, fill in the blanks and source the file
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Requirements

  * [Elixir 1.5.x](https://elixir-lang.org/install.html)

## Environment

This project utilized environment variables for secrets and app configuration.

Begin by copying `.env.sample` into `.env` file, which should never be added into version control. You can load environment variables defined in `.env` file into your environment by running

```
source .env
```

## Documentation

This project has Swagger API documentation generated with [phoenix_swagger](https://github.com/xerions/phoenix_swagger).

Documentation is automatically generated on deployments. You can manually generate it by running

```
mix phx.swagger.generate priv/static/swagger.json -r TribevibeWeb.Router -e TribevibeWeb.Endpoint
```

## Debugging

To debug code, you can stop the execution at a desired place by adding

```
require IEx;

# Debugger will stop here
IEx.pry
```

Next start a new IEx session with

```
iex -S mix phx.server
```

Execution should stop at `IEx.pry`, and you can restart it with `respawn`.

## Deployment

This project is deployed as Docker image to [futuswarm](https://futuswarm.play.futurice.com/). After the initial setup make sure you have access to deploy `tribevibe-server`.

Set `SECRET_KEY_BASE` env variable to some generated secret value. You can generate new secrets with `mix phx.gen.secret`.

Begin by building the latest image.

```
docker build -t futurice/tribevibe-server:$(git rev-parse --short HEAD) --build-arg secret_key_base=$SECRET_KEY_BASE .
```

Next push the image to swarm, and deploy it to production.

```
playswarm image:push -i futurice/tribevibe-server -t $(git rev-parse --short HEAD)
playswarm app:deploy -i futurice/tribevibe-server -t $(git rev-parse --short HEAD) -n tribevibe-server
```

If connection to Officevibe API does not work, make sure that env variables are correctly set using `playswarm config:set`.

## Maintenance

You can view application logs with

```
playswarm app:logs -n tribevibe-server | sort
```
