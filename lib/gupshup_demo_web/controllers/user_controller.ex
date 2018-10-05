defmodule GupshupDemoWeb.UserController do
  use GupshupDemoWeb, :controller

  import SweetXml
  import XmlBuilder

  alias GupshupDemo.Auth
  alias GupshupDemo.Auth.User

  action_fallback(GupshupDemoWeb.FallbackController)

  def index(conn, _params) do
    users = Auth.list_users()
    render(conn, "index.json", users: users)
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Auth.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", user_path(conn, :show, user))
      |> render("show.json", user: user)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Auth.get_user!(id)
    render(conn, "show.json", user: user)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Auth.get_user!(id)

    with {:ok, %User{} = user} <- Auth.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Auth.get_user!(id)

    with {:ok, %User{}} <- Auth.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end

  def sign_in(conn, %{"email" => email, "password" => password}) do
    case GupshupDemo.Auth.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> put_session(:current_user_id, user.id)
        |> put_status(:ok)
        |> render(GupshupDemoWeb.UserView, "sign_in.json", user: user)

      {:error, message} ->
        conn
        |> delete_session(:current_user_id)
        |> put_status(:unauthorized)
        |> render(GupshupDemoWeb.ErrorView, "401.json", message: message)
    end
  end

  def xml_parse(conn, %{xml: doc}) do
    # result =
    #   doc
    #   |> xpath(
    #     ~x"//matchups/matchup"l,
    #     name: ~x"./name/text()"S,
    #     winner: [
    #       ~x".//team/id[.=ancestor::matchup/@winner-id]/..",
    #       name: ~x"./name/text()"S
    #     ]
    #   )

    result =
      doc
      |> xpath(
        ~x"//message/SMS"l,
        msg_type: ~x"./msg_type/text()"S,
        mask: ~x"./mask/text()"S,
        send_to: ~x"./send_to/text()"S
      )

    # IO.inspect(result)

    cause_id = gen_cause_id(19)

    IO.puts("""
    ........ LOOP STARTED .......

    length: #{length(result)}, cause_id: #{cause_id}
    """)

    spawn(fn -> call_walkins_api(cause_id, result) end)

    # response = %{
    #   item: %{
    #     status: "success",
    #     id:
    #       "Your file is being processed. Transaction id #{cause_id}. \nPlease refer upload history below for final status.",
    #     phone: %{},
    #     details: %{}
    #   },
    #   data: %{
    #     causeId: cause_id
    #   }
    # }

    xmlResponse =
      XmlBuilder.doc(:response, [
        element(:item, [
          element(:status, "success"),
          element(
            :id,
            "Your file is being processed. Transaction id #{cause_id}. \nPlease refer upload history below for final status."
          ),
          element(:phone),
          element(:details)
        ]),
        element(:data, [
          element(:causeId, cause_id)
        ])
      ])
      |> XmlBuilder.generate()

    # IO.inspect(xmlResponse)

    conn |> render(GupshupDemoWeb.UserView, "xml_response.xml", response: xmlResponse)
  end

  defp gen_cause_id(limit) do
    Stream.repeatedly(fn -> Enum.random(0..9) end) |> Enum.take(limit) |> Enum.join()
  end

  defp call_walkins_api(cause_id, [head | tail] = smsList) when length(smsList) > 0 do
    # IO.puts("""
    # length: #{length(smsList)}, cause_id: #{cause_id}
    # """)

    # IO.inspect(head)

    external_id = cause_id <> "-" <> gen_cause_id(18)
    delivered_ts = gen_cause_id(13)
    status = Enum.random(["SUCCESS", "FAIL", "SUCCESS"])

    params = %{
      externalId: external_id,
      deliveredTS: delivered_ts,
      status: status,
      phoneNo: head.send_to
    }

    params = if status == "FAIL" do
        params
        |> Map.put(:cause, "DND_FAIL")
    else
      params
    end

    # HTTPoison.get!("http://localhost:9090/", %{}, params: params)

    HTTPoison.get!("http://192.168.4.7:3001/realtime-sms-report-callback-sqs", %{}, params: params)
    spawn(fn -> call_walkins_api(cause_id, tail) end)
  end

  defp call_walkins_api(_cause_id, _smsList) do
    IO.puts("........ LOOP COMPLETED ........")
  end
end
