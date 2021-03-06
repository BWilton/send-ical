CREATE OR REPLACE FUNCTION ical_event 
/* 
This will generate the an icalendar meesage that complies to the iCalendar (RFC 5545) spec
this ical_event will need to be embeded in an email
*/
(
  p_summary         IN VARCHAR2   
, p_organizer_name  IN VARCHAR2   
, p_organizer_email IN VARCHAR2
, p_start_date      IN DATE
, p_end_date        IN DATE
, p_location        IN VARCHAR2 := NULL
, p_description     IN VARCHAR2 := NULL
, p_uid             IN VARCHAR2 := NULL
, p_trigger         IN VARCHAR2 := NULL   --(Code defaults to 60 minute warning 60M = 60 minutes before event)
, p_version         IN VARCHAR2 := NULL   --(Code defaults it to 2.0 if null)
, p_prodid          IN VARCHAR2 := NULL   --(Code defaults it to '-//Company Name//NONSGML ICAL_EVENT//EN' if null)
, p_calscale        IN VARCHAR2 := NULL   --(Code defaults it to GREGORIAN if null)
, p_method          IN VARCHAR2 := NULL   --(Code defaults it to REQUEST if null) REQUEST or CANCEL are valid options
, p_recurrence      IN VARCHAR2 := 'N'    -- N= not a recurring event i.e. single event
, p_frequency       IN VARCHAR2 := NULL   -- DAILY,WEEKLY,MONTHLY,YEARLY bewteen events
, p_interval        IN NUMBER   := NULL   --the number of day, weeks or months between events
, p_count           IN NUMBER   := NULL)  --the number of occurrances 

   RETURN VARCHAR2   

AS     

   l_retval VARCHAR2(32767);
   l_lf     CHAR(2) := chr(13)||chr(10);     

BEGIN  

   l_retval := ''  
      || 'BEGIN:VCALENDAR' || l_lf
      || 'VERSION:' || nvl(p_version,'2.0') || l_lf
      || 'PRODID:' || nvl(p_prodid,'-//Company Id//NONSGML ICAL_EVENT//EN') || l_lf
      || 'CALSCALE:' || nvl(p_calscale,'GREGORIAN') || l_lf
      || 'METHOD:' || nvl(p_method,'REQUEST') || l_lf
      
      /* Time zone example
      || 'BEGIN:VTIMEZONE' || l_lf
	    || 'TZID:Pacific/Auckland' || l_lf
	    || 'BEGIN:STANDARD' || l_lf
	    || 'DTSTART:20070430T000000' || l_lf
	    || 'RRULE:FREQ=YEARLY;INTERVAL=1;BYMONTH=4;BYDAY=1SU' || l_lf
	    || 'TZOFFSETFROM:+1300' || l_lf
	    || 'TZOFFSETTO:+1200' || l_lf
	    || 'TZNAME:NZST' || l_lf
	    || 'END:STANDARD' || l_lf
	    || 'BEGIN:DAYLIGHT' || l_lf
	    || 'DTSTART:20070930T020000' || l_lf 
	    || 'RRULE:FREQ=YEARLY;INTERVAL=1;BYMONTH=9;BYDAY=-1SU' || l_lf
	    || 'TZOFFSETFROM:+1200' || l_lf
	    || 'TZOFFSETTO:+1300' || l_lf
	    || 'TZNAME:NZDT' || l_lf
	    || 'END:DAYLIGHT' || l_lf
	    || 'END:VTIMEZONE' || l_lf
      */
      
      || 'BEGIN:VEVENT' || l_lf
      || 'LOCATION:' || p_location || l_lf
      || 'SUMMARY:' || p_summary || l_lf
      || 'DESCRIPTION:' ||REPLACE(REPLACE(REPLACE( p_description,'<br>','\n'),chr(10),'\n'),chr(13),'\n') || l_lf--strip out linefeeds from the description
      || 'ORGANIZER;CN="' || p_organizer_name || '":MAILTO:' || p_organizer_email || l_lf
      /* When using timezone --Strongly recommend using timezones to prevent issues with Exchange 2016
      || 'DTSTART;TZID=Pacific/Auckland:' || to_char(p_start_date,'YYYYMMDD') || 'T' || to_char(p_start_date,'HH24MISS') || l_lf
      || 'DTEND;TZID=Pacific/Auckland:'   || to_char(p_end_date,'YYYYMMDD') || 'T' || to_char(p_end_date,'HH24MISS') || l_lf
      || 'DTSTAMP;TZID=Pacific/Auckland:' || to_char(SYSDATE,'YYYYMMDD') || 'T' || to_char(SYSDATE,'HH24MISS') || l_lf
      */
      || 'DTSTART:' || to_char(p_start_date,'YYYYMMDD') || 'T' || to_char(p_start_date,'HH24MISS') || l_lf
      || 'DTEND:' || to_char(p_end_date,'YYYYMMDD') || 'T' || to_char(p_end_date,'HH24MISS') || l_lf
      || 'RESOURCES:Mobile AVL' || l_lf
      || 'DTSTAMP:' || to_char(SYSDATE,'YYYYMMDD') || 'T' || to_char(SYSDATE,'HH24MISS') || l_lf
      || 'UID:' || nvl(p_uid,rawtohex(sys_guid())) || '1@corrections.govt.nz' || l_lf
      || 'SEQUENCE:' || 1 || l_lf
      ||CASE WHEN nvl(p_method,'REQUEST') = 'CANCEL' THEN 
        'STATUS:CANCELLED'
       ELSE  
       'STATUS:CONFIRMED' END ||  l_lf 
      --if the event recurs then add a recurrence rule
      ||CASE WHEN p_recurrence = 'Y' AND p_frequency IS NOT NULL AND p_interval  IS NOT NULL AND p_count IS NOT NULL  THEN
        'RRULE:FREQ='||p_frequency||';INTERVAL='||p_interval||';COUNT='||p_count||l_lf
      ELSE NULL
      END
      -- if there is a trigger add an alarm
      -- an alarm is a reminder prior to a meeting
      || CASE WHEN p_trigger IS NOT NULL THEN 
         'BEGIN:VALARM' || l_lf
        || 'TRIGGER:-PT'||p_trigger|| l_lf 
        || 'REPEAT:1' || l_lf
        || 'DURATION:PT'||p_trigger || l_lf
        || 'ACTION:DISPLAY' || l_lf
        || 'DESCRIPTION:' || p_description || l_lf
        || 'END:VALARM' || l_lf ELSE NULL END
      || 'END:VEVENT' || l_lf
      || 'END:VCALENDAR';

   RETURN l_retval; 
       
END ical_event;
/

CREATE OR REPLACE PROCEDURE send_ical_email 
/* 
This procedure will send an email via utl.smtp the value passed into p_body_ical is the ical event generated by generated by a function ical_event.
the Corrections smtp server address is hard coded into this procedure
*/(
   p_from      IN VARCHAR2
 , p_to        IN VARCHAR2
 , p_subj      IN VARCHAR2
 , p_body_html IN VARCHAR2
 , p_body_ical IN VARCHAR2
 , p_mail_serv IN VARCHAR2
 , p_mail_port IN VARCHAR2 := '25'
 , p_method    IN VARCHAR2 := 'REQUEST'--REQUEST = new appointment, CANCEL = Meeting Cancellation
)
  
AS
 
   l_connection utl_smtp.connection;
   l_lf         CHAR(2) := chr(13)||chr(10);   --Chr(13) is the Carriage Return and Chr(10) is the Line Feed character
   l_msg_body   VARCHAR2(32767);
  
BEGIN
   --Build the body of the email. This wraps the ical event in the appropriate header and footer that will define the message as an calendar event
   l_msg_body :=
         'Content-class: urn:content-classes:calendarmessage' || l_lf
      || 'MIME-Version: 1.0' || l_lf
      || 'Content-Type: multipart/alternative;' || l_lf
      || ' boundary="----_=_NextPart"' || l_lf
      || 'Subject: ' || p_subj || l_lf 
      || 'From: <' || p_from || '> ' || l_lf 
      || 'To: ' || p_to || l_lf 
      || '------_=_NextPart' || l_lf
      || 'Content-Type: text/plain;' || l_lf
      || ' charset="iso-8859-1"' || l_lf
      || 'Content-Transfer-Encoding: quoted-printable' || l_lf
      || l_lf
      || 'You must have an HTML enabled client to view this message.' || l_lf
      || l_lf
      || '------_=_NextPart' || l_lf
      || 'Content-Type: text/html;' || l_lf
      || ' charset="iso-8859-1"' || l_lf
      || 'Content-Transfer-Encoding: quoted-printable' || l_lf
      || l_lf
      || p_body_html || l_lf
      || l_lf
      || '------_=_NextPart' || l_lf
      || 'Content-class: urn:content-classes:calendarmessage' || l_lf
      || 'Content-Type: text/calendar;' || l_lf
      || '  method='||p_method||';' || l_lf
      || '  name="meeting.ics"' || l_lf
      || 'Content-Transfer-Encoding: 8bit' || l_lf
      || l_lf
      || p_body_ical || l_lf
      || l_lf
      || '------_=_NextPart--';
   --Open connection to smtp server
   l_connection := utl_smtp.open_connection(p_mail_serv);
   --Pass in the domain of the sender this is normally the same as the smtp server
   utl_smtp.helo(l_connection, p_mail_serv);
   -- initiate a mail transaction
   utl_smtp.mail(l_connection, p_from);
   --specify the recipient 
   utl_smtp.rcpt(l_connection, p_to);
   --specify the body of an e-mail 
   utl_smtp.DATA(l_connection, l_msg_body);
   --terminate the SMTP session and disconnect from the server
   utl_smtp.quit(l_connection);
    
END send_ical_email;
/
