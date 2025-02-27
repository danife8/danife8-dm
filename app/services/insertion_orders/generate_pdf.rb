module InsertionOrders
  require "prawn"
  require "prawn/table"
  require "fileutils"

  class GeneratePdf
    include ActionView::Helpers::NumberHelper
    include MasterRelationshipHelper
    include MediaMixHelper
    include MediaPlanHelper

    LOGO_WIDTH = 125
    CELL_FONT_SIZE = 9
    SPACING = 12
    CELL_PADDING = 2
    CELL_BG_COLOR = "e7e6e6"
    LINK_COLOR = "4472c4"

    def initialize(io)
      @io = io
    end

    attr_reader :io

    def call
      generate_pdf
    end

    private

    def generate_pdf
      file = Tempfile.new(["unsigned_io_#{io.id}", ".pdf"], Rails.root.join("tmp"))
      file.binmode

      Prawn::Document.generate(file.path) do |pdf|
        create_top_section(pdf)
        pdf.move_down SPACING

        create_budget_table(pdf)
        pdf.move_down SPACING

        create_traffic_instructions_table(pdf)
        pdf.move_down SPACING

        create_billing_info_table(pdf)
        pdf.move_down SPACING

        create_acceptance_table(pdf)
      end

      file.rewind

      file
    end

    def create_top_section(pdf)
      initial_y = pdf.cursor
      document_half = pdf.bounds.width / 2
      table_column_widths = {0 => document_half / 3, 1 => document_half - (document_half / 3)}

      # Digital Mouth table aligned to the top of the page
      pdf.bounding_box([0, initial_y], width: document_half) do
        table_data = [
          [{content: "DIGITAL MOUTH CONTACT", colspan: 2}],
          ["Account Manager", io.media_plan.reviewer.full_name.upcase],
          ["Email", create_link(pdf, "mailto:#{io.media_plan.reviewer.email}", io.media_plan.reviewer.email)],
          ["Phone", create_link(pdf, "tel:#{io.media_plan.reviewer.phone_number}", io.media_plan.reviewer.phone_number)]
        ]
        create_table(pdf, table_data, document_half, table_column_widths, {align: :center})
      end

      pdf.move_down SPACING

      first_table_y = pdf.cursor

      # Logo and contact info aligned to the top of the page
      pdf.bounding_box([pdf.bounds.right - document_half, initial_y], width: document_half) do
        logo_path = Rails.root.join("app", "assets", "images", "logo-blue.png")
        table_data = [[{image: logo_path, colspan: 2, position: :right, image_width: LOGO_WIDTH}]]

        pdf.table(table_data, width: document_half, cell_style: {align: :right}) do |table|
          table.cells.border_width = 0
          table.cells.padding = 1
        end

        pdf.move_down 10

        # Logo copy
        table_data = [
          ["Digital Mouth Advertising"],
          ["2237 Park Road, Charlotte, NC 28203"],
          ["(980) 443-6622 | digitalmouth.com"]
        ]
        pdf.table(table_data, width: document_half, cell_style: {size: CELL_FONT_SIZE, font_style: :bold, align: :right}) do |table|
          table.cells.border_width = 0
          table.cells.padding = 1
        end
      end

      # Agency table
      pdf.bounding_box([0, first_table_y], width: document_half) do
        table_data = [
          [{content: "AGENCY CONTACT", colspan: 2}],
          ["Agency", io.client.agency.name.upcase],
          ["Name", io.client.name.upcase],
          ["Email", create_link(pdf, "mailto:#{io.client.contact_email}", io.client.contact_email)]
        ]
        create_table(pdf, table_data, document_half, table_column_widths, {align: :center})
      end

      pdf.move_down SPACING

      # Campaign table
      pdf.bounding_box([0, pdf.cursor], width: document_half) do
        flight_days = "#{io.media_brief.campaign_starts_on.strftime("%m/%d/%Y")} - #{io.media_brief.campaign_ends_on.strftime("%m/%d/%Y")}"

        gender_target = io.media_brief.demographic_genders_list.any? ? io.media_brief.demographic_genders_list.map(&:label).join(" - ") : "-"
        age_target = io.media_brief.demographic_ages_list.any? ? io.media_brief.demographic_ages_list.join(" | ") : "-"

        table_data = [
          [{content: "CAMPAIGN INFORMATION", colspan: 2}],
          ["Client", io.media_brief.client.name.upcase],
          ["Campaign", io.media_brief.title.upcase],
          ["Flight Dates", flight_days],
          ["Age Target", io.media_brief.all_demographics ? "All" : age_target],
          ["Gender Target", io.media_brief.all_demographics ? "All" : gender_target],
          ["Geo Target", GeographicTarget.find(io.media_brief.geographic_target).short_label]
        ]
        create_table(pdf, table_data, document_half, table_column_widths, {align: :center})
      end
    end

    def create_budget_table(pdf)
      table_data = [
        ["CHANNEL", "PLATFORM", "OBJECTIVE", "TARGET STRATEGY", "TARGET", "EST CPM", "EST IMPR", "BUDGET"]
      ]

      io.media_plan.media_plan_output.media_plan_output_rows.each do |row|
        table_data << [
          row.campaign_channel.label,
          row.media_platform.label,
          io.media_brief.campaign_objective.label,
          row.target_strategy.label,
          row.target.label,
          format_cpm(row.master_relationship.cpm, row.target_strategy),
          format_impr(row.impressions, row.target_strategy),
          currency(row.amt)
        ]
      end

      table_data << [
        {content: "Total Budget", colspan: 6, font_style: :bold, background_color: CELL_BG_COLOR},
        {content: sum_imprs(io.media_plan), font_style: :bold, background_color: CELL_BG_COLOR},
        {content: sum_media_plan_amts(io.media_plan), font_style: :bold, background_color: CELL_BG_COLOR}
      ]
      create_table(pdf, table_data, nil, nil, {align: :center})
    end

    def create_traffic_instructions_table(pdf)
      ad_formats = io.media_plan.media_plan_output.media_plan_output_rows.map { |r| r.ad_format.label }.uniq.join("\n")
      asset_requirements = io.media_plan.media_plan_output.media_plan_output_rows.map { |r| ad_format_requirements(r.ad_format.value) }.uniq.join("\n")
      table_data = [
        [{content: "Traffic Instructions", colspan: 2}],
        ["Provided by Digital Mouth", "Digital Campaign Management, Creative Rotation, Targeting, Reporting and Optimization of Digital Campaigns."],
        ["Provided by Client", "Failure to provide creative assets 5 business days prior to launch date may result in delay of campaign."],
        ["Ad Formats", ad_formats],
        ["Asset Requirements", asset_requirements],
        ["Traffic Destination", create_link(pdf, io.media_brief.destination_url, io.media_brief.destination_url)]
      ]
      table_column_widths = {0 => pdf.bounds.width / 6, 1 => pdf.bounds.width - (pdf.bounds.width / 6)}
      create_table(pdf, table_data, nil, table_column_widths)
    end

    def create_billing_info_table(pdf)
      table_column_widths = {0 => pdf.bounds.width / 6, 1 => pdf.bounds.width - (pdf.bounds.width / 6)}
      table_data = [
        [{content: "Billing Information", colspan: 2}],
        ["Billing & Payment", "Billing based off Digital Mouth ad-served impressions. Invoices sent monthly based on delivery."],
        ["Payment Terms", "Invoices due 30 days from date of issue, 15% monthly interest fee past 30 days. ACH, eCheck, Wire, CC (3% processing fee) accepted."],
        ["Additional Terms", "This IO is subject to the T&Cs set forth here and within the MSA. By signing this you also agree to the T&Cs within the MSA."]
      ]
      create_table(pdf, table_data, nil, table_column_widths)
    end

    def create_acceptance_table(pdf)
      table_column_widths = {0 => pdf.bounds.width / 6, 1 => pdf.bounds.width - (pdf.bounds.width / 6)}
      table_data = [
        [{content: "Acceptance by Advertiser/Client", colspan: 2}],
        ["Name", ""],
        ["Signature", ""],
        ["Date", ""]
      ]
      create_table(pdf, table_data, nil, table_column_widths)
    end

    def create_link(pdf, href, text)
      pdf.make_cell(content: "<a href='#{href}'>#{text}</a>", inline_format: true, text_color: LINK_COLOR)
    end

    def create_table(pdf, table_data, table_width = nil, column_widths = nil, cell_style_hash = {})
      cell_style = {size: CELL_FONT_SIZE, padding: CELL_PADDING}.merge(cell_style_hash)
      width = table_width || pdf.bounds.width
      pdf.table(table_data, width:, cell_style:) do |table|
        table.row(0).font_style = :bold
        table.row(0).align = :center
        table.row(0).background_color = CELL_BG_COLOR

        if column_widths
          table.column_widths = column_widths
        end
      end
    end

    def ad_format_requirements(key)
      {
        app_ext_fb:	"SI: 1080x1080 JPG/PNG + App Copy, Caro: Min 2, Max 10, 1080x1080 JPG/PNG + App Copy",
        app_ext_sem: "Responsive Search Ad Copy + App Extension Copy + App",
        audio:	":30, Under 100 Words, MP3, OGG, WAV, Max 500 MB + 300x250 JPG Companion Banner",
        call_ext_sem:	"Responsive Search Ad Copy + Call Extension Copy & Number",
        ctv_video: ":15, :30, :60, 1920x1080 Resolution, MP4, AVI, MOV, MPEG, Max 200 MB",
        display_ad:	"160x600, 320x50, 300x250, 728x90, 300x600, GIF, JPG, PNG, Max 200 MB",
        lead_ext_sem:	"Responsive Search Ad Copy + Lead Extension Copy",
        lead_form_fb:	"SI: 1080x1080 JPG/PNG + Lead Form Copy",
        location_ext_sem:	"Responsive Search Ad Copy + Location Extension Copy & Address",
        promo_fb:	"SI: 1080x1080 JPG/PNG + Promo Copy, Caro: Min 2, Max 10, 1080x1080 JPG/PNG + Promo Copy",
        promo_sem:	"Responsive Search Ad Copy + Promo Extension Copy + Item",
        std_fb:	"SI: 1080x1080 JPG/PNG + Copy, Caro: Min 2/Max 10, 1080x1080 JPG/PNG + Copy",
        std_sem:	"Responsive Search Ad Copy",
        video:	":15, :30, :60, 1920x1080 Resolution, MP4, AVI, MOV, MPEG, Max 200 MB"
      }[key.to_sym]
    end
  end
end
