defmodule Hexpm.Web.PasswordController do
  use Hexpm.Web, :controller

  def show(conn, %{"username" => username, "key" => key}) do
    conn
    |> put_session("reset_username", username)
    |> put_session("reset_key", key)
    |> redirect(to: Routes.password_path(conn, :show))
  end

  def show(conn, _params) do
    username = get_session(conn, "reset_username")
    key = get_session(conn, "reset_key")

    if username && key do
      changeset = User.update_password(%User{}, %{})

      conn
      |> delete_session("reset_username")
      |> delete_session("reset_key")
      |> render_show(username, key, changeset)
    else
      conn
      |> put_flash(:error, "Invalid password reset key.")
      |> redirect(to: Routes.page_path(Hexpm.Web.Endpoint, :index))
    end
  end

  def update(conn, params) do
    params = params["user"]
    username = params["username"]
    key = params["key"]
    revoke_all_keys? = (params["revoke_all_keys"] || "yes") == "yes"

    case Users.password_reset_finish(
           username,
           key,
           params,
           revoke_all_keys?,
           audit: audit_data(conn)
         ) do
      :ok ->
        conn
        |> clear_session()
        |> configure_session(renew: true)
        |> put_flash(:info, "Your account password has been changed to your new password.")
        |> redirect(to: Routes.page_path(Hexpm.Web.Endpoint, :index))

      :error ->
        conn
        |> put_flash(:error, "Failed to change your password.")
        |> redirect(to: Routes.page_path(Hexpm.Web.Endpoint, :index))

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render_show(username, key, changeset)
    end
  end

  defp render_show(conn, username, key, changeset) do
    render(
      conn,
      "show.html",
      title: "Choose a new password",
      container: "container page page-xs password-view",
      username: username,
      key: key,
      changeset: changeset
    )
  end
end
