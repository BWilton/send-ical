DECLARE
 
   l_ical_event VARCHAR2(32767);
 
BEGIN
 
   l_ical_event := ical_event(
      p_start_date      => TO_DATE(:P301_START_DATE, 'DD-MON-YYYY HH24:MI')
    , p_end_date        => TO_DATE(:P301_END_DATE ,'DD-MON-YYYY HH24:MI')
    , p_summary         => 'Test meeting summary'
    , p_organizer_name  => 'Ben Wilton'
    , p_organizer_email => 'ben@example.com'
    , p_trigger         => '60M'
    , p_uid             => rawtohex(sys_guid()) || '@example.com' --this is just a long uniqueish string
    , p_description     => 'This the text that appears in the meeting notes'
    , p_location        => 'Wellington, New Zealand'
    , p_mail_serv       => 'mail.example.com'
   );
 
   schemaapexcmmn.brw_send_ical_email( 
      p_to        => 'someone.else@example.com'
    , p_from      => 'ben@example.com'
    , p_subj      => 'Test meeting summary'
    , p_body_html => 'This the text that appears in the email'
    , p_body_ical => l_ical_event
   );
    
END;
