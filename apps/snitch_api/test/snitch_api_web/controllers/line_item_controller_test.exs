defmodule SnitchApiWeb.LineItemControllerTest do
  use SnitchApiWeb.ConnCase, async: true
  import Plug.Conn
  alias Snitch.Repo
  alias SnitchApi.Accounts
  import Snitch.Factory
  # alias Snitch.Data.Model.Order, as: OrderModel

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    user = build(:user_with_no_role)

    role = build(:role, name: "user")

    Repo.insert(role, on_conflict: :nothing)

    {:ok, registered_user} = Accounts.create_user(user)

    # create the token
    {:ok, token, _claims} = SnitchApi.Guardian.encode_and_sign(registered_user)

    # add authorization header to request
    conn = put_req_header(conn, "authorization", "Bearer #{token}")

    conn = assign(conn, :current_user, registered_user)

    # pass the connection and the user to the test

    {:ok, conn: conn}
  end

  describe "Line Items" do
    test "Adding/updating item", %{conn: conn} do
      user = conn.assigns[:current_user]
      order = insert(:order, user_id: user.id)

      variant = insert(:product, shipping_category: insert(:shipping_category))

      line_item =
        :line_item
        |> build(unit_price: nil)
        |> Map.take([:quantity, :unit_price])

      data = %{
        data: %{
          type: "line_item",
          attributes: line_item,
          relationships: %{
            order: %{
              data: %{
                id: order.id,
                type: "order"
              }
            },
            product: %{
              data: %{
                id: variant.id,
                type: "variant"
              }
            }
          }
        }
      }

      conn = post(conn, line_item_path(conn, :create, data))

      assert json_response(conn, 200)["data"]
    end

    test "Updating a line item", %{conn: conn} do
      line_item = insert(:line_item, order: insert(:order), product: insert(:product))

      data = %{
        data: %{
          id: line_item.id,
          type: "line_item",
          attributes: %{
            quantity: 10
          }
        }
      }

      conn = patch(conn, line_item_path(conn, :update, line_item.id, data))

      assert %{
               "attributes" => %{
                 "quantity" => 10
               }
             } = json_response(conn, 200)["data"]
    end
  end
end
