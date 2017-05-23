
$(function() {

    function submit_send() {
//treatment of , as decimal separator: parseFloat(str.replace(',','.').replace(' ',''))
alert(9);
        API.create_order("S", "Op", $('#partner').val(), $('#value').val(), '', '', '', '').success(function () {
            $.pnotify({
                title: Messages("messages.api.success"),
                text: Messages("messages.api.success.ordercreatedsuccessfully"),
                styling: 'bootstrap',
                type: 'success',
                text_escape: true
            });
        });
        window.location.href = $('#hidden_form_validation_messages').attr('dashboard_url');
    }

    $(document).ready(function () {
        fillMessages();
    });
    $('.triggers_submit').click(function () {
        FormValidating();
    });


    function FormValidating() {
        var decimal_separator = $('#hidden_fees_information').attr('decimal_separator');
        var value_s = $('#value').val();
        if (decimal_separator == ",")
            value_s = value_s.replace(decimal_separator, ".");
        if ($.isNumeric(value_s)) {
            var value = parseFloat(value_s);
            if (value > 0) {
                //(value_s + " <= " + parseFloat($('#hidden_fees_information').attr('wallet_available')) + " + " +  parseFloat($('#hidden_fees_information').attr('wallet_crypto'))  + " - " +  parseFloat($('#hidden_fees_information').attr('wallet_crypto_onhold')) + " - " + parseFloat($('#total_send_fee').val()));
                if (parseFloat(value_s) <= parseFloat($('#hidden_fees_information').attr('wallet_available')) + parseFloat($('#hidden_fees_information').attr('wallet_crypto')) - parseFloat($('#hidden_fees_information').attr('wallet_crypto_onhold')) - parseFloat($('#total_send_fee').val())) {
                    if ($('#partner').val() != "00" && $('#partner_account').val() != "")
                    // calling API function:
                        submit_send(value);
                    else {
                        alert($('#hidden_form_validation_messages').attr('accountinformationisincomplete'));
                    }
                } else {
                    alert($('#hidden_form_validation_messages').attr('amountnotavailable'));
                }
            } else {
                alert($('#hidden_form_validation_messages').attr('valuemustbegreaterthanzero'));
            }
        } else {
            alert($('#hidden_form_validation_messages').attr('valuemustbenumerical'));
        }
    }
});
