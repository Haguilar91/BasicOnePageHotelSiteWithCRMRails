require "test_helper"

class PhoneNumberTest < ActiveSupport::TestCase
  test "a number is required, a label is not" do
    assert PhoneNumber.new(number: "+52 442 212 3456").valid?
    assert_not PhoneNumber.new.valid?
  end

  test "only one line at a time can be the WhatsApp line" do
    first = PhoneNumber.create!(number: "+52 1", whatsapp_active: true)
    second = PhoneNumber.create!(number: "+52 2", whatsapp_active: true)

    assert_not first.reload.whatsapp_active
    assert second.reload.whatsapp_active
  end

  test "only one line at a time can be the call line" do
    first = PhoneNumber.create!(number: "+52 1", call_active: true)
    second = PhoneNumber.create!(number: "+52 2")
    second.update!(call_active: true)

    assert_not first.reload.call_active
    assert second.reload.call_active
  end

  test "the two roles are independent of each other" do
    whatsapp = PhoneNumber.create!(number: "+52 1", whatsapp_active: true)
    calls = PhoneNumber.create!(number: "+52 2", call_active: true)

    assert whatsapp.reload.whatsapp_active, "flagging a call line must not clear the WhatsApp line"
    assert calls.reload.call_active
  end

  test "clearing a flag leaves the other rows alone" do
    first = PhoneNumber.create!(number: "+52 1", whatsapp_active: true)
    second = PhoneNumber.create!(number: "+52 2")

    first.update!(whatsapp_active: false)

    assert_not first.reload.whatsapp_active
    assert_not second.reload.whatsapp_active
  end

  test "whatsapp_line and call_line fall back to the first row when nothing is flagged" do
    first = PhoneNumber.create!(number: "+52 1", position: 0)
    PhoneNumber.create!(number: "+52 2", position: 1)

    assert_equal first, PhoneNumber.whatsapp_line
    assert_equal first, PhoneNumber.call_line
  end

  test "whatsapp_line and call_line prefer the flagged row over the first one" do
    PhoneNumber.create!(number: "+52 1", position: 0)
    flagged = PhoneNumber.create!(number: "+52 2", position: 1, whatsapp_active: true, call_active: true)

    assert_equal flagged, PhoneNumber.whatsapp_line
    assert_equal flagged, PhoneNumber.call_line
  end

  test "whatsapp_line and call_line are nil when there are no numbers at all" do
    assert_nil PhoneNumber.whatsapp_line
    assert_nil PhoneNumber.call_line
  end

  test "listed returns only visible numbers, in admin order" do
    second = PhoneNumber.create!(number: "+52 2", position: 2)
    first = PhoneNumber.create!(number: "+52 1", position: 1)
    PhoneNumber.create!(number: "+52 3", position: 3, visible: false)

    assert_equal [ first.id, second.id ], PhoneNumber.listed.pluck(:id)
  end

  test "digits strips everything a wa.me link cannot take" do
    assert_equal "524422123456", PhoneNumber.new(number: "+52 (442) 212-3456").digits
  end

  test "dialable keeps the leading plus so tel: links dial internationally" do
    assert_equal "+524422123456", PhoneNumber.new(number: "+52 (442) 212-3456").dialable
  end

  test "the label is translatable" do
    phone = create_es(PhoneNumber, number: "+52 1", label: "Recepción")
    Mobility.with_locale(:en) { phone.update!(label: "Front desk") }

    Mobility.with_locale(:es) { assert_equal "Recepción", phone.reload.label }
    Mobility.with_locale(:en) { assert_equal "Front desk", phone.reload.label }
  end
end
