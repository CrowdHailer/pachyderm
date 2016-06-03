defmodule LotteryCorp.Web.PageView do
  use LotteryCorp.Web.Web, :view

  def uuid(%{uuid: uuid}) do
    uuid
  end

  def as_string({id, :no_change}) do
    "NO CHANGE"
  end
  def as_string({id, {thing, who}}) do
    "Game #{id}: #{thing} #{who}"
  end
end
