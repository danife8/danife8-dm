# README
## Último feature implementado
Toda la seccion Campaigns, Documents y DocumentsRequest fueron desarrolladas por mi parte. Así como el controlador stimulus Drag-and-Drop de archivos.
El flujo completo se compone desde la creación de Campaigns en un callback de InsertionOrder, hasta la carga de archivos Documents a un bucket en S3 utilizando direct_upload.

## Algunas seciones donde tuve participacion
* /app/assets/modules/drag-and-drop.scss
* /app/controllers/campaigns_controller.rb
* /app/controllers/documents_controller.rb
* /app/controllers/documents_requests_controller.rb
* /app/javascript/controllers/add_client_user_controller.js
* /app/javascript/controllers/drag_and_drop_controller.js
* /app/javascript/controllers/request_documents_controller.js
* /app/jobs/documents_request_reminder_job.rb
* /app/mailers/documents_request_reminder_mailer.rb
* /app/models/campaign.rb
* /app/models/campaign_user.rb
* /app/models/document.rb
* /app/models/document_request.rb
* /app/models/user.rb
* /app/policies/campaign_policy.rb
* /app/policies/user_policy.rb
* /app/policies/document.rb
* /app/policies/documents_request.rb
* /app/policies/insertion_order.rb
* /app/services/find_or_create_user_service.rb
* /app/views/campaigns
* /app/views/documents
* /app/views/documents_requests
* /app/views/insertion_orders

## Dependencies

Ruby library dependencies are managed with [Bundler](http://bundler.io/) in the `Gemfile`.

Runtime dependencies:

* [Ruby 3.3](http://www.ruby-lang.org/en/)
* [Node.js ~> 22.11](https://nodejs.org/en/)
* [Yarn ~> 1.22](https://yarnpkg.com/en/)
* [Postgres >= 14.7](http://www.ruby-lang.org/en/)
* [Redis >= 6.2](https://redis.io/)
