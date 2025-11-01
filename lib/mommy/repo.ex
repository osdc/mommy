defmodule Mommy.Repo do
  use Ecto.Repo,
    otp_app: :mommy,
    adapter: Ecto.Adapters.Postgres
end
