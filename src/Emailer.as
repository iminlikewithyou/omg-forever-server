package
{

    import components.Console;

    import flash.events.*;
    import flash.utils.*;

    import org.bytearray.smtp.events.SMTPEvent;
    import org.bytearray.smtp.mailer.SMTPMailer;

    /**
     * ...
     * @author Olin Kirkland
     */
    public class Emailer
    {
        private var host: String;
        private var port: int;
        private var address: String;
        private var password: String;

        public function Emailer(host: String, port: int, address: String, password: String): void
        {
            this.host = host;
            this.port = port;
            this.address = address;
            this.password = password;
        }

        public function send(recipient: String, subject: String, message: String): void
        {

            // Setup mailer
            var myMailer: SMTPMailer = new SMTPMailer(host, port);
            myMailer.addEventListener(SMTPEvent.MAIL_SENT, onMailSent);
            myMailer.addEventListener(SMTPEvent.MAIL_ERROR, onMailReply);
            myMailer.addEventListener(SMTPEvent.CONNECTED, onConnected);
            myMailer.addEventListener(SMTPEvent.DISCONNECTED, onDisconnected);
            myMailer.addEventListener(SMTPEvent.AUTHENTICATED, onAuthSuccess);
            myMailer.addEventListener(SMTPEvent.BAD_SEQUENCE, onBadSequence);
            myMailer.addEventListener(IOErrorEvent.IO_ERROR, onIOError);

            myMailer.connect(host, port);

            function sendEmail(): void
            {
                // Send Email
                myMailer.sendHTMLMail(address, recipient, subject, message, "OMG Forever");
            }

            function onAuthSuccess(e: SMTPEvent): void
            {
                sendEmail();
            }

            function onConnected(e: SMTPEvent): void
            {
                myMailer.authenticate(address, password);
            }

            function onMailSent(e: SMTPEvent): void
            {
                Console.log("Email sent to " + recipient, "email");

                // Remove event listeners
                myMailer.removeEventListener(SMTPEvent.MAIL_SENT, onMailSent);
                myMailer.removeEventListener(SMTPEvent.MAIL_ERROR, onMailReply);
                myMailer.removeEventListener(SMTPEvent.CONNECTED, onConnected);
                myMailer.removeEventListener(SMTPEvent.DISCONNECTED, onDisconnected);
                myMailer.removeEventListener(SMTPEvent.AUTHENTICATED, onAuthSuccess);
                myMailer.removeEventListener(SMTPEvent.BAD_SEQUENCE, onBadSequence);
                myMailer.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
                myMailer.close();
            }

            function onMailReply(e: SMTPEvent): void
            {
                if (e.result.code == 250)
                    onMailSent(e);
            }

            function onDisconnected(e: SMTPEvent): void
            {
            }

            function onBadSequence(e: SMTPEvent): void
            {
            }

            function onIOError(e: IOErrorEvent): void
            {
            }
        }
    }
}
