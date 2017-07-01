import play.api.db.DB
import play.api.i18n.{ MessagesApi, I18nSupport }
import play.api.Play.current
import models._
import play.api._
import play.libs.Akka
import service.txbitsUserService
import usertrust.{ UserTrustModel, UserTrustService }
import anorm._

package object globals {

  def settings(country: String, key: String, data_type: Integer = 2): Any = {
    if (data_type == 0) {
      // Boolean
      val return_variable0 = Play.current.configuration.getBoolean(country.concat(".").concat(key)).getOrElse(false)
      if ((return_variable0).getClass == (false).getClass && !(return_variable0 == false && Play.current.configuration.getBoolean(country.concat(".").concat(key)).getOrElse(true)))
        return return_variable0
      else {
        Logger.warn("Error on country-setting key. Country: %s, Key: %s, Type: boolean".format(country, key))
        return false
      }
    }
    if (data_type == 1) {
      // Double
      val return_variable1 = Play.current.configuration.getDouble(country.concat(".").concat(key)).getOrElse(-1.01)
      if ((return_variable1).getClass == (0.1).getClass && return_variable1 != -1.01)
        return return_variable1
      else {
        Logger.warn("Error on country-setting key. Country: %s, Key: %s, Type: double".format(country, key))
        return -1.01
      }
    }
    if (data_type == 2) {
      // String
      val return_variable2 = Play.current.configuration.getString(country.concat(".").concat(key)).getOrElse("Not Set")
      if ((return_variable2).getClass == ("oi").getClass && return_variable2 != "Not Set")
        return return_variable2
      else {
        Logger.warn("Error on country-setting key. Country: %s, Key: %s, Type: string".format(country, key))
        return "Not Set"
      }
    }
    return key.concat(" ")
  }

  val masterDB = "default"
  val masterDBWallet = "wallet"
  val masterDBTrusted = "trust"

  //Initiating Database
  initiateDatabase()
  var initiate_country_as_number = 1
  initiateCountry("br") // Brazil
  // @@@ only first ountry works for now... When unique user defined with country then other countries would work
  //initiateCountry("dc") // Default Country
  temporaryInitiateCountry("dc")
  temporaryPopulateDatabase()

  val userModel = new UserModel(masterDB)
  val logModel = new LogModel(masterDB)
  val engineModel = new EngineModel(masterDB)
  val userTrustModel = new UserTrustModel(masterDBTrusted)

  // create UserTrust actor
  val userTrustActor = current.configuration.getBoolean("usertrustservice.enabled").getOrElse(false) match {
    case true => Some(Akka.system.actorOf(UserTrustService.props(userTrustModel)))
    case false => None
  }

  def initiateDatabase(): Boolean = {
    try {
      if (Play.current.configuration.getBoolean("meta.devdb").getOrElse(false)) {
        DB.withConnection(globals.masterDB)({ implicit c =>
          SQL"""
        begin;
          delete from users_name_info;
          delete from users_connections;
          delete from users_passwords;
          delete from users_tfa_secrets;
          delete from users_backup_otps;
          delete from totp_tokens_blacklist;
          delete from event_log;
          delete from tokens;
          delete from trusted_action_requests;
          delete from balances;
          delete from orders;
          delete from currencies;
          delete from users;
          delete from image;
  
          insert into image (image_id, name) values (0, 'null');
          insert into users(id, email, user_country) values (0, 'system_account', 'dc');
        commit;
          """.execute()
        })
      }
      return true
    } catch {
      case error: Throwable =>
        Logger.error(error.toString)
        return false
    }
  }

  def initiateCountry(current_country: String): Boolean = {
    val country_code_s = settings(current_country, "country_code", 2).asInstanceOf[String]
    val currency_code_s = settings(current_country, "country_currency_code", 2).asInstanceOf[String]
    val initial_capital_d = settings(current_country, "country_system_initial_crypto_capital", 1).asInstanceOf[Double]
    val local_admin1_s = settings(current_country, "country_local_admin1", 2).asInstanceOf[String]
    val local_admin1_country_s = settings(current_country, "country_local_admin1_country", 2).asInstanceOf[String]
    val local_admin2_s = settings(current_country, "country_local_admin2", 2).asInstanceOf[String]
    val local_admin2_country_s = settings(current_country, "country_local_admin2_country", 2).asInstanceOf[String]
    val global_admin1_s = settings(current_country, "country_global_admin1", 2).asInstanceOf[String]
    val global_admin1_country_s = settings(current_country, "country_global_admin1_country", 2).asInstanceOf[String]
    val global_admin2_s = settings(current_country, "country_global_admin2", 2).asInstanceOf[String]
    val global_admin2_country_s = settings(current_country, "country_global_admin2_country", 2).asInstanceOf[String]
    val partner1_account_s = settings(current_country, "country_partner1_account", 2).asInstanceOf[String]
    val partner2_account_s = settings(current_country, "country_partner2_account", 2).asInstanceOf[String]
    val partner1_name_s = settings(current_country, "country_partner1_name", 2).asInstanceOf[String]
    val partner1_url_s = settings(current_country, "country_partner1_url", 2).asInstanceOf[String]
    val partner1_info_s = settings(current_country, "country_partner1_info", 2).asInstanceOf[String]
    val partner2_name_s = settings(current_country, "country_partner2_name", 2).asInstanceOf[String]
    val partner2_url_s = settings(current_country, "country_partner2_url", 2).asInstanceOf[String]
    val partner2_info_s = settings(current_country, "country_partner2_info", 2).asInstanceOf[String]
    try {
      if (Play.current.configuration.getBoolean("meta.devdb").getOrElse(false)) {
        DB.withConnection(globals.masterDB)({ implicit c =>
          SQL"""
        begin;
          select currency_insert(${initiate_country_as_number}, ${currency_code_s}, ${country_code_s}, 0, 0);
          insert into balances (user_id, currency) select 0, ${currency_code_s};
          update balances set balance = 0, balance_c = ${initial_capital_d} where currency = ${currency_code_s} and user_id = 0;

          if not user_exists (${local_admin1_s}, $local_admin1_country_s) then
            select create_user(${local_admin1_s}, $local_admin1_country_s, 'asd123', true, null, 'en', true, '');
            select insert_as_admin(${country_code_s}, ${local_admin1_s}, $local_admin1_country_s, 'admin_l1');
          end if;

          if not user_exists (${local_admin2_s}, $local_admin2_country_s) then
            select create_user(${local_admin2_s}, $local_admin2_country_s, 'asd123', true, null, 'en', true, '');
            select insert_as_admin(${country_code_s}, ${local_admin2_s}, $local_admin2_country_s, 'admin_l2');
          end if;

          if not user_exists (${global_admin1_s}, $global_admin1_country_s) then
            select create_user(${global_admin1_s}, $global_admin1_country_s, 'aaa222', true, null, 'en', true, '');
            select insert_as_admin(${country_code_s}, ${global_admin1_s}, $global_admin1_country_s, 'admin_g1');
          end if;

          if not user_exists (${global_admin2_s}, $global_admin2_country_s) then
            select create_user(${global_admin2_s}, $global_admin2_country_s, 'aaa222', true, null, 'en', true, '');
            select insert_as_admin(${country_code_s}, ${global_admin2_s}, $global_admin2_country_s, 'admin_g2');
          end if;

          select create_user(${partner1_account_s}, ${currency_code_s}, 'zxc111', true, null, 'en', true, '');
          select create_user(${partner2_account_s}, ${currency_code_s}, 'zxc111', true, null, 'en', true, '');


          insert into users_name_info (user_id, first_name, middle_name, last_name, doc1, doc2, doc3, doc4, doc5, ver1, ver2, ver3, ver4, ver5) select id, 'Marcelo', 'Simão', 'Boczko', '999.090.089-98', 'doc_pdf.pdf', 'doc_pdf.pdf', '(12)99324-0988', 'doc5', true, true, true, true, true from users where email=${local_admin1_s};
          insert into users_name_info (user_id, first_name, middle_name, last_name, doc1, doc2, doc3, doc4, doc5, ver1, ver2, ver3, ver4, ver5) select id, 'Yura', '', 'Mitrofanov', '097.455.645-09', '140.png', 'doc_38.jpg', '(53)30823-098', 'doc5', false, false, false, true, false from users where email=${global_admin1_s};
          insert into users_name_info (user_id, first_name, middle_name, last_name, doc1, doc2, doc3, doc4, doc5, ver1, ver2, ver3, ver4, ver5) select id, ${partner1_name_s}, ${partner1_url_s}, ${partner1_info_s}, '', '', '', '', '', false, false, false, false, false from users where email=${partner1_account_s};
          insert into users_name_info (user_id, first_name, middle_name, last_name, doc1, doc2, doc3, doc4, doc5, ver1, ver2, ver3, ver4, ver5) select id, ${partner2_name_s}, ${partner2_url_s}, ${partner2_info_s}, '', '', '', '', '', false, false, false, false, false from users where email=${partner2_account_s};

          insert into users_connections (user_id, bank, agency, account, partner, partner_account) select (select id from users where email=${local_admin1_s}), '745', 'Agency B', 'Account B', 'Crypto-Trade.net', 'partner_account@gmail.com';
          insert into users_connections (user_id, bank, agency, account, partner, partner_account) select (select id from users where email=${global_admin1_s}), '341', '8788-X', '677.789-9', 'Crypto-Trade.net', '';
          insert into users_connections (user_id, bank, agency, account, partner, partner_account) select (select id from users where email=${partner1_account_s}), '', '', '', ${partner1_url_s}, ${partner1_account_s};
          insert into users_connections (user_id, bank, agency, account, partner, partner_account) select (select id from users where email=${partner2_account_s}), '', '', '', ${partner2_url_s}, ${partner2_account_s};

        commit;
          """.execute()
        })
      }
      initiate_country_as_number = initiate_country_as_number + 1
      return true
    } catch {
      case error: Throwable =>
        Logger.error(error.toString)
        return false
    }
  }

  def temporaryInitiateCountry(current_country: String): Boolean = {
    try {
      val country_code_s = settings(current_country, "country_code", 2).asInstanceOf[String]
      val currency_code_s = settings(current_country, "country_currency_code", 2).asInstanceOf[String]
      val initial_capital_d = settings(current_country, "country_system_initial_crypto_capital", 1).asInstanceOf[Double]
      val local_admin1_s = settings(current_country, "country_local_admin1", 2).asInstanceOf[String]
      val global_admin1_s = settings(current_country, "country_global_admin1", 2).asInstanceOf[String]
      val partner1_account_s = settings(current_country, "country_partner1_account", 2).asInstanceOf[String]
      val partner2_account_s = settings(current_country, "country_partner2_account", 2).asInstanceOf[String]
      val partner1_name_s = settings(current_country, "country_partner1_name", 2).asInstanceOf[String]
      val partner1_url_s = settings(current_country, "country_partner1_url", 2).asInstanceOf[String]
      val partner1_info_s = settings(current_country, "country_partner1_info", 2).asInstanceOf[String]
      val partner2_name_s = settings(current_country, "country_partner2_name", 2).asInstanceOf[String]
      val partner2_url_s = settings(current_country, "country_partner2_url", 2).asInstanceOf[String]
      val partner2_info_s = settings(current_country, "country_partner2_info", 2).asInstanceOf[String]
      if (Play.current.configuration.getBoolean("meta.devdb").getOrElse(false)) {
        DB.withConnection(globals.masterDB)({ implicit c =>
          SQL"""
        begin;
          select currency_insert(${initiate_country_as_number}, ${currency_code_s}, ${country_code_s}, 0, 0);
          insert into balances (user_id, currency) select 0, ${currency_code_s};
          update balances set balance = 0, balance_c = ${initial_capital_d} where currency = ${currency_code_s} and user_id = 0;

          select create_user(${local_admin1_s}, 'br', 'Fada00Fada', true, null, 'en', true, '');
          select create_user(${global_admin1_s}, 'ru', 'aaa222', true, null, 'en', true, '');

          select create_user(${partner1_account_s}, 'fr', 'aaa222', true, null, 'en', true, '');
          select create_user(${partner2_account_s}, 'fr', 'aaa222', true, null, 'en', true, '');
          select insert_as_admin(${country_code_s}, ${global_admin1_s}, 'admin_g1');
          select insert_as_admin(${country_code_s}, ${local_admin1_s}, 'admin_l1');

        commit;
          """.execute()
        })
      }
      initiate_country_as_number = initiate_country_as_number + 1
      return true
    } catch {
      case error: Throwable =>
        Logger.error(error.toString)
        return false
    }
  }

  def temporaryPopulateDatabase(): Boolean = {
    try {
      if (Play.current.configuration.getBoolean("meta.devdb").getOrElse(false)) {
        DB.withConnection(globals.masterDB)({ implicit c =>
          SQL"""
        begin;
          select insert_as_admin('br', 'mboczko@yahoo.com', 'admin_o1');
          update balances set balance = 5000 where currency = 'BRL' and user_id = (select id from users where email='mboczko@yahoo.com');

          select create_user('a', 'dc', 'a', true, null, 'en', false, '');
          select create_user('test@hotmail.ru', 'br', 'pass01', true, null, 'ru', false, '');
          select create_user('test@gmail.com', 'br', 'pass02', true, null, 'en', false, '');
          select create_user('test@yahoo.com.br', 'br', 'pass03', true, null, 'pt', false, '');
          select create_user('testru@gmail.ru', 'br', 'pass04', true, null, 'ru', false, '');
  
          insert into users_name_info (user_id, first_name, middle_name, last_name, doc1, doc2, doc3, doc4, doc5, ver1, ver2, ver3, ver4, ver5) select id, 'Test', 'Test-middle_name', 'Tes-last_name', '', '', '', '', 'doc5', false, false, false, false, false from users where email='test@hotmail.ru';
          insert into users_name_info (user_id, first_name, middle_name, last_name, doc1, doc2, doc3, doc4, doc5, ver1, ver2, ver3, ver4, ver5) select id, 'Test', '', 'last name', '566.432.789-03', 'doc39.jpg', '140.png', '(11)32580-342', 'doc5', false, false, false, true, false from users where email='test@gmail.com';
          insert into users_name_info (user_id, first_name, middle_name, last_name, doc1, doc2, doc3, doc4, doc5, ver1, ver2, ver3, ver4, ver5) select id, 'TestBR', '', 'sobrenome', '', 'doc39.jpg', 'doc_37.JPG', '(15)99707-0000', '', false, false, false, true, false from users where email='test@yahoo.com.br';
          insert into users_name_info (user_id, first_name, middle_name, last_name, doc1, doc2, doc3, doc4, doc5, ver1, ver2, ver3, ver4, ver5) select id, 'TestRU', '', 'skovsk', '343.782.121-34', 'doc_38.jpg', '', '(11)95454-0993', 'doc5', true, true, true, true, false from users where email='testru@gmail.ru';
          insert into users_name_info (user_id, first_name, middle_name, last_name, doc1, doc2, doc3, doc4, doc5, ver1, ver2, ver3, ver4, ver5) select id, 'Aaaaa', 'midA', 'LastA', '333.988.454-08', 'doc_PDF.pdf', 'doc_37.jpg', '(19)23240-434', 'doc5', true, true, true, true, false from users where email='a';
  
          insert into users_connections (user_id, bank, agency, account, partner, partner_account) select (select id from users where email='a'), '237', 'Agency A', 'Account A', 'Crypto-Trade.net', 'qwqwqw@ioe.cs';
          insert into users_connections (user_id, bank, agency, account, partner, partner_account) select (select id from users where email='test@yahoo.com.br'), '237', '65665', '00685343-0', '', '';
          insert into users_connections (user_id, bank, agency, account, partner, partner_account) select (select id from users where email='testru@gmail.ru'), '341', '352323-c', '67345-9', '', '';
  
        commit;
          """.execute()

        })
      }
      return true
    } catch {
      // XXX: any kind of error in the SQL above will cause this cryptic exception:
      // org.postgresql.util.PSQLException: Cannot change transaction read-only property in the middle of a transaction.
      case error: Throwable =>
        Logger.error(error.toString)
        return false
    }
  }

  def numberFormat(value: AnyVal): String = {
    if (settings("dc", "country_decimal_separator").asInstanceOf[String] == ',')
      return value.toString
    else
      return (value.toString).replace('.', ',')
  }

  def calculate_local_fee(order_type: String, initial_value: BigDecimal = 0): BigDecimal = {
    val default_country = "dc" // ### Must change to user's country
    val percentage = (100 - settings(default_country, "country_fees_global_percentage", 1).asInstanceOf[Double]) * 0.01
    var low_value_fee = 0.0
    if (initial_value < settings(default_country, "country_minimum_value", 1).asInstanceOf[Double]) {
      low_value_fee = settings(default_country, "country_minimum_value", 1).asInstanceOf[Double] * 0.02
    }
    if (order_type == "D") {
      return initial_value * settings(default_country, "country_fee_deposit_percent", 1).asInstanceOf[Double] * 0.01 * percentage + low_value_fee
    } else if (order_type == "S") {
      return initial_value * settings(default_country, "country_fee_send_percent", 1).asInstanceOf[Double] * 0.01 * percentage
    } else if (order_type == "S.") {
      return initial_value * settings(default_country, "country_fee_send_percent", 1).asInstanceOf[Double] * 0.01 * percentage
    } else if (order_type == "DCS") {
      return initial_value * (settings(default_country, "country_fee_deposit_percent", 1).asInstanceOf[Double] + settings(default_country, "country_fee_send_percent", 1).asInstanceOf[Double]) * 0.01 * percentage + low_value_fee
    } else if (order_type == "W") { // withdrawal to a preferential bank
      return settings(default_country, "country_nominal_fee_withdrawal_preferential_bank", 1).asInstanceOf[Double] + initial_value * settings(default_country, "country_fee_withdrawal_percent", 1).asInstanceOf[Double] * 0.01 * percentage + low_value_fee
    } else if (order_type == "W.") { // withdrawal to a non preferential bank
      return settings(default_country, "country_nominal_fee_withdrawal_not_preferential_bank", 1).asInstanceOf[Double] + initial_value * settings(default_country, "country_fee_withdrawal_percent", 1).asInstanceOf[Double] * 0.01 * percentage + low_value_fee
    } else if (order_type == "RFW") { // withdrawal to a preferential bank
      return settings(default_country, "country_nominal_fee_withdrawal_preferential_bank", 1).asInstanceOf[Double] + initial_value * (settings(default_country, "country_fee_withdrawal_percent", 1).asInstanceOf[Double] + settings(default_country, "country_fee_tofiat_percent", 1).asInstanceOf[Double]) * 0.01 * percentage + low_value_fee
    } else if (order_type == "RFW.") { // withdrawal to a non preferential bank
      return settings(default_country, "country_nominal_fee_withdrawal_preferential_bank", 1).asInstanceOf[Double] + settings(default_country, "country_nominal_fee_withdrawal_not_preferential_bank", 1).asInstanceOf[Double] + initial_value * (settings(default_country, "country_fee_withdrawal_percent", 1).asInstanceOf[Double] + settings(default_country, "country_fee_tofiat_percent", 1).asInstanceOf[Double]) * 0.01 * percentage + low_value_fee
    } else if (order_type == "F") {
      return initial_value * settings(default_country, "country_fee_tofiat_percent", 1).asInstanceOf[Double] * 0.01 * percentage
    } else return 0
  }

  def calculate_global_fee(order_type: String, initial_value: BigDecimal = 0): BigDecimal = {
    val default_country = "dc" //### Must change to user's country
    val percentage = settings(default_country, "country_fees_global_percentage", 1).asInstanceOf[Double] * 0.01
    if (order_type == "D") {
      return initial_value * settings(default_country, "country_fee_deposit_percent", 1).asInstanceOf[Double] * 0.01 * percentage
    } else if (order_type == "S") {
      return initial_value * settings(default_country, "country_fee_send_percent", 1).asInstanceOf[Double] * 0.01 * percentage
    } else if (order_type == "S.") {
      return initial_value * settings(default_country, "country_fee_send_percent", 1).asInstanceOf[Double] * 0.01 * percentage
    } else if (order_type == "DCS") {
      return initial_value * (settings(default_country, "country_fee_deposit_percent", 1).asInstanceOf[Double] + settings(default_country, "country_fee_send_percent", 1).asInstanceOf[Double]) * 0.01 * percentage
    } else if (order_type == "W" || order_type == "W.") {
      return initial_value * settings(default_country, "country_fee_withdrawal_percent", 1).asInstanceOf[Double] * 0.01 * percentage
    } else if (order_type == "RFW" || order_type == "RFW.") {
      return initial_value * (settings(default_country, "country_fee_withdrawal_percent", 1).asInstanceOf[Double] + settings(default_country, "country_fee_tofiat_percent", 1).asInstanceOf[Double]) * 0.01 * percentage
    } else if (order_type == "F") {
      return initial_value * settings(default_country, "country_fee_tofiat_percent", 1).asInstanceOf[Double] * 0.01 * percentage
    } else return 0
  }

}

object Global extends GlobalSettings {

  override def onStart(app: Application) {
    Logger.info("Application has started")
    // This is a somewhat hacky way to exit after statup so that we can apply database changes without stating the app
    if (Play.current.configuration.getBoolean("meta.exitimmediately").getOrElse(false)) {
      Logger.warn("Exiting because of meta.exitimmediately config set to true.")
      System.exit(0)
    }
    txbitsUserService.onStart()
  }

  override def onStop(app: Application) {
    Logger.info("Application shutdown...")
    txbitsUserService.onStop()
  }
}
