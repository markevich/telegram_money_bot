defmodule MarkevichMoney.Priorbank.Api do
  alias Finch.Response

  @user_agent "PriorMobile3/3.17.03.22 (Android 24; versionCode 37)"
  @api_url "https://www.prior.by"
  @pool_size 25

  def child_spec do
    {Finch,
     name: __MODULE__,
     pools: %{
       @api_url => [size: @pool_size]
     }}
  end

  def authenticated?(%{user_session: nil}) do
    false
  end

  def authenticated?(connection) do
    {:ok, response} = get_cards(connection)

    response.status != 401
  end

  def get_cards(connection) do
    url = make_api_url("/Cards")

    headers = [
      {"client_id", connection.client_secret},
      {"User-Agent", @user_agent},
      {"Authorization", "bearer #{connection.access_token}"},
      {"Accept", "application/json, text/plain, */*"},
      {"Content-Type", "application/json;charset=UTF-8"}
    ]

    body =
      %{
        "usersession" => connection.user_session
      }
      |> Jason.encode!()

    response =
      :post
      |> Finch.build(url, headers, body)
      |> Finch.request(__MODULE__)
  end

  def get_cards_details(connection) do
    url = make_api_url("/Cards/CardDesc")

    headers = [
      {"client_id", connection.client_secret},
      {"User-Agent", @user_agent},
      {"Authorization", "bearer #{connection.access_token}"},
      {"Accept", "application/json, text/plain, */*"},
      {"Content-Type", "application/json;charset=UTF-8"}
    ]

    body =
      %{
        "usersession" => connection.user_session,
        "ids" => [],
        "dateToSpecified" => false,
        "dateFromSpecified" => true,
        "dateFrom" => connection.last_fetched_at
      }
      |> Jason.encode!()

    response =
      :post
      |> Finch.build(url, headers, body)
      |> Finch.request(__MODULE__)
      |> get_json_body()
  end

  def authenticate(login, encrypted_password) do
    tokens = get_mobile_token()
    salt = get_salt(tokens.auth_access_token, tokens.client_secret, login)
    password_hash = calculate_password_hash(salt, encrypted_password)

    login_response = auth_login(login, tokens, password_hash)

    if login_response["success"] do
      tokens = %{
        client_secret: tokens.client_secret,
        access_token: login_response["result"]["access_token"],
        user_session: login_response["result"]["userSession"]
      }

      {:ok, tokens}
    else
      raise(login_response)
    end
  end

  def auth_login(login, tokens, password_hash) do
    url = make_api_url("/Authorization/Login")

    headers = [
      {"Authorization", "bearer #{tokens.auth_access_token}"},
      {"client_id", tokens.client_secret},
      {"User-Agent", @user_agent},
      {"Accept", "application/json, text/plain, */*"},
      {"Content-Type", "application/json;charset=UTF-8"}
    ]

    body =
      %{
        "login" => login,
        "password" => password_hash,
        "lang" => "RUS"
      }
      |> Jason.encode!()

    response =
      :post
      |> Finch.build(url, headers, body)
      |> Finch.request(__MODULE__)
      |> get_json_body()
  end

  # users ->
  #    priorbank_authorizations
  #    alfabank_authorizations

  def get_mobile_token do
    url = make_api_url("/Authorization/MobileToken")

    body =
      :get
      |> Finch.build(url)
      |> Finch.request(__MODULE__)
      |> get_json_body()

    %{
      auth_access_token: Map.get(body, "access_token"),
      client_secret: Map.get(body, "client_secret")
    }
  end

  def calculate_password_hash(login_salt, password) do
    # password_hash = :crypto.hash(:sha512, password) |> Base.encode16 |> String.downcase()

    :crypto.hash(:sha512, "#{password}#{login_salt}") |> Base.encode16() |> String.downcase()
  end

  def get_salt(auth_access_token, client_secret, login) do
    url = make_api_url("/Authorization/GetSalt")

    headers = [
      {"Authorization", "bearer #{auth_access_token}"},
      {"client_id", client_secret},
      {"User-Agent", @user_agent},
      {"Accept", "application/json, text/plain, */*"},
      {"Content-Type", "application/json;charset=UTF-8"}
    ]

    body =
      %{
        "login" => login,
        "lang" => "RUS"
      }
      |> Jason.encode!()

    response =
      :post
      |> Finch.build(url, headers, body)
      |> Finch.request(__MODULE__)
      |> get_json_body()

    response
    |> Map.get("result")
    |> Map.get("salt")
  end

  def get_json_body({_state, %Finch.Response{body: body, headers: _headers, status: status}}) do
    body
    |> Jason.decode!()
  end

  def make_api_url(path) do
    "#{@api_url}/api3/api#{path}"
  end
end
