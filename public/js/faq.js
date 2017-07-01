$(function(){

    var data_variable = Handlebars.compile($("#faq-body-script-template").html());
    function showFaqBody(){
        var data_input = [
            { level: 1, key: "contract" },
            { level: 2, key: "contract.thiscontract" },
            { level: 2, key: "contract.thecontractstarts" },
            { level: 2, key: "contract.thiscontractcanbemodified" },
            { level: 1, key: "parts" },
            { level: 2, key: "parts.thecompany" },
            { level: 2, key: "parts.partners" },
            { level: 2, key: "parts.users" },
            { level: 1, key: "signin" },
            { level: 2, key: "signin.userisresponsible" },
            { level: 2, key: "signin.userdeclares" },
            { level: 2, key: "signin.thecompanykeepstheright" },
            { level: 1, key: "contractend" },
            { level: 2, key: "contractend.thecontractendswhen" },
            { level: 3, key: "contractend.thecontractendswhen.userspersonalinfoinvalid" },
            { level: 3, key: "contractend.thecontractendswhen.underpartnersrequest" },
            { level: 3, key: "contractend.thecontractendswhen.thecompanyconsiders" },
            { level: 3, key: "contractend.thecontractendswhen.duringtemporaryinterruptions" },
            { level: 3, key: "contractend.thecontractendswhen.bytheendofcompany" },
            { level: 2, key: "contractend.remaindutesandrights" },
            { level: 1, key: "intermediationservice" },
            { level: 2, key: "intermediationservice.thiscontract" },
            { level: 1, key: "usersdutesandrights" },
            { level: 2, key: "usersdutesandrights.userswithrecordsnotverified" },
            { level: 2, key: "usersdutesandrights.userwithrecordsverified" },
            { level: 2, key: "usersdutesandrights.userwillbeallowed" },
            { level: 1, key: "legalactions" },
            { level: 2, key: "legalactions.companykeepstheright" }
        ];
        var data = [];
        var level = [1, 0, 0, 0, 0, 1]; // levels with 1 are not used, but must exist
        var p_number = "";
        var p_class = "";
        var p_level = 0;
        for (var i = 0; i < data_input.length; i++) {
            p_level = data_input[i].level;
            level[p_level]++;
            level[p_level + 1] = 0;
            p_number = level[1] + "";
            p_class = "p_level1";

            if(p_level > 1){
                p_number = p_number + "." + level[2];
                p_class = "p_leveln";
            }
            if(p_level > 2){
                p_number = p_number + "." + level[3];
            }
            if(p_level > 3){
                p_number = p_number + "." + level[4];
            }
            p_number = p_number + " - ";
            data.push({
                p_number: p_number,
                p_text: Messages("directpay.faq." + data_input[i].key),
                p_class: p_class,
                p_level1: level[1],
                p_level: p_level
            });
        }
        $('#faq-body-script-position').html(data_variable(data));
    }
    showFaqBody();


    $('.p_level1').live('click', function() {
        var p_id = $(this).attr('id').substring(1);
        if ($('.2_' + p_id).css('display') == 'none') {
            $('.2_' + p_id).css('display', 'block');
            $('.3_' + p_id).css('display', 'block');
            $('.4_' + p_id).css('display', 'block');
        } else {
            $('.2_' + p_id).css('display', 'none');
            $('.3_' + p_id).css('display', 'none');
            $('.4_' + p_id).css('display', 'none');
        }
        });

});


