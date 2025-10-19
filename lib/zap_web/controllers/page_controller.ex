defmodule ZapWeb.PageController do
  use ZapWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
