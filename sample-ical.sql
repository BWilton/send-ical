DECLARE
 
   l_ical_event VARCHAR2(32767);
 
BEGIN
 
   l_ical_event := ical_event(
      p_start_date      => trunc(sysdate+2/24,'HH24')
    , p_end_date        => trunc(sysdate+3/24,'HH24')
    , p_summary         => 'Test meeting summary'
    , p_organizer_name  => 'Ben Wilton'
    , p_organizer_email => 'ben@example.com'
    , p_trigger         => '60M'
    , p_uid             => rawtohex(sys_guid()) || '@example.com' --this is just a long uniqueish string
    , p_description     => 'This the text that appears in the meeting notes'
    , p_location        => 'Wellington, New Zealand'
   );
 
   send_ical_email( 
      p_to        => 'someone.else@example.com'
    , p_from      => 'ben@example.com'
    , p_subj      => 'Test meeting summary'
    , p_body_html => 'This the text that appears in the email'
    , p_body_ical => l_ical_event
    , p_mail_serv => 'mail.example.com'
	   , p_method    => 'REQUEST'
   );
    
END;
