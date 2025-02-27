# Resources to manage archived agency clients.
class Archive::ClientsController < ApplicationController
  before_action :set_client, only: %i[update]

  # GET /archive/clients
  def index
    authorize Client

    client_scope = policy_scope(Client)
      .only_deleted
      .order(:id)
      .page(params[:page])
      .includes(:agency)

    # Search by name when query is present.
    @filter_params = filter_params
    if @filter_params[:q].present?
      client_scope = client_scope.search_by_name(@filter_params[:q])
    end

    @clients = client_scope
  end

  # PATCH/PUT /archive/clients/:id
  def update
    authorize @client
    if @client.recover
      redirect_to client_url(@client), notice: "Client was successfully restored."
    else
      redirect_to archive_clients_url, notice: "There was a problem restoring the client."
    end
  end

  private

  # @return [ActionController::Parameters] permitted client filter params
  def filter_params
    params.fetch(:filter, {}).permit(:q)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_client
    @client = policy_scope(Client).only_deleted.find(params[:id])
  end
end
