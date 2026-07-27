class InvoiceService
  def initialize(job_card, current_user)
    @job_card = job_card
    @current_user = current_user
  end

  def create_from_estimates
    estimates = @job_card.estimates.where(status: :approved)
    return nil if estimates.empty?

    invoice = Invoice.new(
      job_card: @job_card, customer: @job_card.customer, branch: @job_card.branch,
      created_by: @current_user
    )

    estimates.each do |estimate|
      estimate.line_items.each do |line_item|
        invoice.line_items.build(
          item_type: line_item.item_type, description: line_item.description,
          spare_part: line_item.spare_part, quantity: line_item.quantity,
          unit: line_item.unit, unit_price: line_item.unit_price,
          total_price: line_item.total_price
        )
      end

      invoice.tax_type = estimate.tax_type
      invoice.cgst_rate = estimate.cgst_rate
      invoice.sgst_rate = estimate.sgst_rate
      invoice.igst_rate = estimate.igst_rate
    end

    invoice.labor_total = invoice.line_items.select { |li| li.item_type == "labor" }.sum(&:total_price)
    invoice.parts_total = invoice.line_items.select { |li| li.item_type == "part" }.sum(&:total_price)
    invoice.subtotal = invoice.labor_total + invoice.parts_total
    if invoice.tax_type == "igst"
      invoice.igst_amount = invoice.subtotal * invoice.igst_rate / 100
      invoice.total_tax = invoice.igst_amount
    else
      invoice.cgst_amount = invoice.subtotal * invoice.cgst_rate / 100
      invoice.sgst_amount = invoice.subtotal * invoice.sgst_rate / 100
      invoice.total_tax = invoice.cgst_amount + invoice.sgst_amount
    end
    invoice.grand_total = invoice.subtotal + invoice.total_tax

    if invoice.save
      @job_card.update(status: :invoiced)
      invoice.line_items.where(item_type: "part").each do |li|
        next unless li.spare_part
        li.spare_part.deduct_stock!(li.quantity.to_i)
        InventoryMovement.create(
          spare_part: li.spare_part, warehouse: Warehouse.first,
          quantity: -li.quantity.to_i, movement_type: :repair_out,
          reference_type: "Invoice", reference_id: invoice.id,
          notes: "Invoice #{invoice.invoice_number}", performed_by: @current_user
        )
      end
      invoice
    end
  end
end
