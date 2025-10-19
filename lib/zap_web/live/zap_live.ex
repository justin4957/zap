defmodule ZapWeb.ZapLive do
  use ZapWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_gif_url, nil)
     |> assign(:current_gif_name, nil)
     |> assign(:bolt_click_count, 0)
     |> assign(:spinning, false)}
  end

  @impl true
  def handle_event("new_gif", _params, socket) do
    case fetch_random_gif() do
      {:ok, gif_url, gif_name} ->
        {:noreply,
         socket
         |> assign(:current_gif_url, gif_url)
         |> assign(:current_gif_name, gif_name)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("bolt_click", _params, socket) do
    new_count = socket.assigns.bolt_click_count + 1

    socket =
      if new_count == 4 do
        # Trigger spin animation and redirect
        socket
        |> assign(:spinning, true)
        |> assign(:bolt_click_count, 0)
        |> push_event("redirect_to_lmgtfy", %{
          gif_name: socket.assigns.current_gif_name || "random gif"
        })
      else
        socket
        |> assign(:bolt_click_count, new_count)
        |> assign(:spinning, false)
      end

    {:noreply, socket}
  end

  defp fetch_random_gif do
    # Using Giphy API - users should set GIPHY_API_KEY env variable
    api_key = System.get_env("GIPHY_API_KEY") || "dc6zaTOxFJmzC"
    url = "https://api.giphy.com/v1/gifs/random?api_key=#{api_key}&rating=g"

    case Req.get(url) do
      {:ok, %{status: 200, body: body}} ->
        gif_url = get_in(body, ["data", "images", "original", "url"])
        gif_name = get_in(body, ["data", "title"]) || "Awesome GIF"
        {:ok, gif_url, gif_name}

      _ ->
        {:error, :fetch_failed}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-purple-600 via-pink-500 to-orange-400 flex flex-col items-center justify-center p-8">
      <div class="text-center mb-8">
        <h1
          class="text-7xl font-bold text-white mb-4 drop-shadow-lg"
          style="text-shadow: 3px 3px 6px rgba(0,0,0,0.3)"
        >
          ⚡ ZAP ⚡
        </h1>
        <p class="text-white text-xl drop-shadow-md">Click the button for a random GIF!</p>
      </div>

      <div class="mb-8 relative">
        <button
          phx-click="bolt_click"
          class={"text-9xl cursor-pointer transform transition-all duration-500 hover:scale-110 #{if @spinning, do: "animate-spin", else: ""}"}
          title="Click me 4 times for a surprise!"
        >
          ⚡
        </button>
      </div>

      <div class="mb-8">
        <button
          phx-click="new_gif"
          class="bg-white text-purple-600 font-bold py-4 px-8 rounded-full text-xl shadow-lg hover:bg-purple-100 transform hover:scale-105 transition-all duration-200 active:scale-95"
        >
          Get Random GIF!
        </button>
      </div>

      <%= if @current_gif_url do %>
        <div class="bg-white rounded-lg shadow-2xl p-4 max-w-2xl">
          <img src={@current_gif_url} alt={@current_gif_name} class="rounded-lg w-full" />
          <p class="text-center mt-4 text-gray-700 font-semibold"><%= @current_gif_name %></p>
        </div>
      <% end %>
    </div>
    """
  end
end
