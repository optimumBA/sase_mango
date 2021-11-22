defmodule SaseMango.InvestBaPostCreator do
  import Wallaby.Browser
  import Wallaby.Query

  def post(data) do
    {:ok, session} = Wallaby.start_session()

    session
    |> visit(System.get_env("INVEST_BA_URL"))
    |> fill_in(text_field("Username:"), with: System.get_env("INVEST_BA_USERNAME"))
    |> fill_in(text_field("Password:"), with: System.get_env("INVEST_BA_PASSWORD"))
    |> click(button("Login"))
    |> fill_in(css("#message"), with: data)
    |> click(button("Submit"))
  end
end
