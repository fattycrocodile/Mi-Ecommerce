defmodule SnitchApi.CodPayment do
  alias BeepBop.Context
  alias Snitch.Data.Model.Order
  alias Snitch.Domain.Order.DefaultMachine
  alias Snitch.Repo

  def make_payment(order_id) do
    with order when not is_nil(order) <- Order.get(order_id) do
      context = Context.new(order)
      transition = DefaultMachine.confirm_purchase_payment(context)
      transition_response(transition)
    else
      _ ->
        {:error, :not_found}
    end
  end

  defp transition_response(%Context{errors: nil, struct: order}) do
    order = Repo.preload(order, :line_items)
    {:ok, order}
  end

  defp transition_response(%Context{errors: errors}) do
    {:error, message} = errors
    {:error, %{message: message}}
  end
end
