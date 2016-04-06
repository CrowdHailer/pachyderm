defmodule LotteryCorp.Web.PageView do
  use LotteryCorp.Web.Web, :view

  def uuid(%{uuid: uuid}) do
    uuid
  end
end
