defmodule MarkevichMoney.Priorbank.Auth do
  alias MarkevichMoney.Priorbank.Api
  alias MarkevichMoney.Priorbank.PriorbankConnection
  alias MarkevichMoney.Repo

  def get_transactions(connection) do
    connection
    |> maybe_update_session()
    |> Api.get_cards_details()
  end

  def maybe_update_session(session) do
    login = session.login
    encrypted_password = session.encrypted_password

    if Api.authenticated?(session) do
      session
    else
      {:ok, new_tokens} = Api.authenticate(login, encrypted_password)

      update_session!(session, new_tokens)
    end
  end

  defp update_session!(
         old_session,
         %{
           client_secret: _client_secret,
           access_token: _access_token,
           user_session: _user_session
         } = attrs
       ) do
    old_session
    |> PriorbankConnection.update_session_changeset(attrs)
    |> Repo.update!()
  end
end
