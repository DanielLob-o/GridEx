defmodule GridExWeb.PageController do
  use GridExWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
