defmodule GupshupDemoWeb.Router do
  use GupshupDemoWeb, :router

  pipeline :api do
    plug(:accepts, ["json", "xml"])
    plug(:fetch_session)
  end

  pipeline :api_auth do
    plug(:ensure_authenticated)
  end

  scope "/api", GupshupDemoWeb do
    pipe_through(:api)
    post("/users/sign_in", UserController, :sign_in)
    post("/xml", UserController, :xml_parse)
    get("/rest", UserController, :optin_sms)
  end


  scope "/api", GupshupDemoWeb do
    pipe_through([:api, :api_auth])
    resources("/users", UserController, except: [:new, :edit])
  end

  defp ensure_authenticated(conn, _opts) do
    current_user_id = get_session(conn, :current_user_id)

    if current_user_id do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> render(GupshupDemoWeb.ErrorView, "401.json", message: "Unauthenticated user")
      |> halt()
    end
  end
end
