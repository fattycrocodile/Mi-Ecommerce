defmodule Snitch.Data.Model.LineItemTest do
  use ExUnit.Case, async: true
  use Snitch.DataCase

  import Mox, only: [expect: 3, verify_on_exit!: 1]
  import Snitch.Factory

  alias Snitch.Data.Model.LineItem

  describe "with valid params" do
    setup :variants
    setup :good_line_items

    test "update_unit_price/1", context do
      %{line_items: line_items} = context
      priced_items = LineItem.update_unit_price(line_items)
      assert Enum.all?(priced_items, fn %{unit_price: price} -> not is_nil(price) end)
    end

    test "compute_total/1", context do
      %{line_items: line_items} = context
      priced_items = LineItem.update_unit_price(line_items)
      assert %Money{} = LineItem.compute_total(priced_items)
    end
  end

  describe "with invalid params" do
    setup :variants
    setup :bad_line_items

    test "update_unit_price/1", %{line_items: line_items} do
      priced_items = LineItem.update_unit_price(line_items)

      assert [
               %{quantity: 2, variant_id: -1},
               %{quantity: nil, unit_price: %Money{}, variant_id: _},
               %{quantity: 2, variant_id: nil}
             ] = priced_items
    end
  end

  describe "compute_total/1 with empty list" do
    setup :verify_on_exit!

    test "when default currency is set" do
      expect(Snitch.Tools.DefaultsMock, :fetch, fn :currency -> {:ok, :INR} end)
      assert Money.zero(:INR) == LineItem.compute_total([])
    end

    test "when default currency is not set" do
      expect(Snitch.Tools.DefaultsMock, :fetch, fn :currency -> {:error, "whatever"} end)

      assert_raise RuntimeError, "whatever", fn ->
        LineItem.compute_total([])
      end
    end
  end

  describe "create/1" do
    setup :variants
    setup :user_with_address

    @tag variant_count: 1
    test "fails without an existing order", %{variants: [v]} do
      assert {:error, :line_item, changeset, %{}} =
               LineItem.create(%{line_item_params(v) | order_id: -1})

      assert %{order_id: ["does not exist"]} = errors_on(changeset)

      assert {:error, :line_item, changeset, %{}} = LineItem.create(line_item_params(v))

      assert %{order_id: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "create/1 for order in `cart` state" do
    setup :variants
    setup :user_with_address

    @tag variant_count: 1
    test "which is empty", %{variants: [v], user: user} do
      order = insert(:order, line_items: [], user: user)

      {:ok, li} = LineItem.create(%{line_item_params(v) | order_id: order.id})
      assert Ecto.assoc_loaded?(li.order)
      assert Ecto.assoc_loaded?(li.order.line_items)
      assert length(li.order.line_items) == 1
    end

    @tag variant_count: 2
    test "with existing line_items", %{variants: [v1, v2], user: user} do
      order = insert(:order, user: user)
      order = struct(order, line_items(%{order: order, variants: [v1]}))

      assert length(order.line_items) == 1
      [li] = order.line_items
      assert li.variant_id == v1.id

      {:ok, li} = LineItem.create(%{line_item_params(v2) | order_id: order.id})
      assert Ecto.assoc_loaded?(li.order)
      assert Ecto.assoc_loaded?(li.order.line_items)
      assert length(li.order.line_items) == 2
    end
  end

  describe "update/1 for order in `cart` state" do
    setup :variants
    setup :user_with_address

    @tag variant_count: 1
    test "with valid params", %{variants: [v], user: user} do
      order = insert(:order, user: user)
      order = struct(order, line_items(%{order: order, variants: [v]}))

      [li] = order.line_items

      params = %{quantity: li.quantity + 1}

      {:ok, li} = LineItem.update(li, params)
      assert Ecto.assoc_loaded?(li.order)
      assert Ecto.assoc_loaded?(li.order.line_items)
      assert length(li.order.line_items) == 1
    end
  end

  describe "delete/1 for order in `cart` state" do
    setup :variants
    setup :user_with_address

    @tag variant_count: 1
    test "with valid params", %{variants: [v], user: user} do
      order = insert(:order, user: user)
      order = struct(order, line_items(%{order: order, variants: [v]}))

      [line_item] = order.line_items

      {:ok, li} = LineItem.delete(line_item)
      assert Ecto.assoc_loaded?(li.order)
      assert Ecto.assoc_loaded?(li.order.line_items)
      assert [] = li.order.line_items
    end
  end

  defp good_line_items(context) do
    %{variants: vs} = context
    quantities = Stream.cycle([2])

    line_items =
      vs
      |> Stream.zip(quantities)
      |> Enum.reduce([], fn {variant, quantity}, acc ->
        [%{variant_id: variant.id, quantity: quantity} | acc]
      end)

    [line_items: line_items]
  end

  defp bad_line_items(context) do
    %{variants: [one, two, three]} = context
    variants = [%{one | id: -1}, two, %{three | id: nil}]
    quantities = [2, nil, 2]

    line_items =
      variants
      |> Stream.zip(quantities)
      |> Enum.map(fn {variant, quantity} ->
        %{variant_id: variant.id, quantity: quantity}
      end)

    [line_items: line_items]
  end

  defp line_item_params(variant) do
    %{
      quantity: 1,
      unit_price: variant.selling_price,
      total: variant.selling_price,
      order_id: nil,
      variant_id: variant.id
    }
  end
end

defmodule Snitch.Data.Model.LineItemDocTest do
  use ExUnit.Case, async: true
  use Snitch.DataCase

  import Snitch.Factory

  alias Snitch.Data.Model

  setup do
    insert(:variant)
    :ok
  end

  doctest Snitch.Data.Model.LineItem
end
