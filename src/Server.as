package
{

    import components.Console;

    import flash.events.*;
    import flash.filesystem.*;
    import flash.net.*;

    public class Server extends EventDispatcher
    {
        private var sessions: Object;
        public var server: ServerSocket;

        private var dataManager: DataManager;

        public function Server(): void
        {
            // Singletons
            dataManager = DataManager.getInstance();

            // Load data from file
            var file: File = File.applicationStorageDirectory.resolvePath("data.json");
            if (!file.exists)
            {
                // No data yet, create an empty file
                var fileStream: FileStream = new FileStream();
                fileStream.open(file, FileMode.WRITE);
                fileStream.writeUTFBytes(JSON.stringify({}));
                fileStream.close();
            }

            // Sessions start empty
            sessions = {};

            // Start the server
            server = new ServerSocket();
            server.bind(Service.PORT);
            server.addEventListener(ServerSocketConnectEvent.CONNECT, handleConnect);
            server.listen();
            Console.log("Started on port " + Service.PORT, "config");
        }

        private function handleConnect(e: ServerSocketConnectEvent): void
        {
            // When a Socket connects
            var session: Session = new Session(e.socket);

            // Session event listeners
            session.addEventListener(Session.DISCONNECT, handleDisconnect);
            session.addEventListener(Session.CONFIRM, handleConfirm);
            session.addEventListener(MessageEvent.DATA, handleDataReceived);
        }

        private function handleConfirm(e: Event): void
        {
            // When a Session that's connected is confirmed (not a "policy connect")
            var session: Session = (e.target as Session);
            sessions[session.id] = session;
            Console.log("Session (" + session.id + ") connected\n  " + session.socket.remoteAddress, "userJoined", {ip: session.socket.remoteAddress});
        }

        private function handleDisconnect(e: Event): void
        {
            // When a Session disconnects
            var session: Session = (e.target as Session);
            delete sessions[session.id];

            Console.log("Session (" + session.id + ") disconnected\n  " + session.socket.remoteAddress, "userLeft", {ip: session.socket.remoteAddress});
        }

        private function handleDataReceived(e: MessageEvent): void
        {
            // Handle all received data from sessions here
            var m: Object = e.data;
            var s: Session = Session(e.target);

            // Reused variables
            var user: Object;

            // Handle messages from all sessions, whether or not they are logged in
            Console.log(JSON.stringify(m), "stats");

            if (m.hasOwnProperty("request"))
            {
                /*
                DATA REQUEST
                 */

                m.request.data = dataManager.getData(m.request.id, m.request.category);
                s.send({"requestReturn": m.request});
            }

            if (m.hasOwnProperty("register"))
            {
                /*
                REGISTER
                 */

                // Check if Beta Key is valid
                if (dataManager.getData(m.register.betaKey, "betaKeys"))
                {
                    // Check if Email is valid
                    if (Service.isValidEmail(m.register.email))
                    {
                        //Check if Email is not already used
                        if (!dataManager.getUserByEmail(m.register.email))
                        {
                            // Add user
                            dataManager.addUser(m.register);

                            // Tell the session to login using its credentials
                            s.send({"action": "rawLogin", "args": {"email": m.register.email, "password": m.register.password}});
                        }
                        else
                        {
                            // Email is already used
                            s.send({startPopup: {id: "error", payload: "emailAlreadyUsed"}});
                        }
                    }
                    else
                    {
                        // Email is not valid
                        s.send({startPopup: {id: "error", payload: "emailNotValid"}});
                    }
                }
                else
                {
                    // Beta Key is invalid
                    s.send({startPopup: {id: "error", payload: "betaKeyNotValid"}});
                }
            }

            if (m.hasOwnProperty("login"))
            {
                /*
                LOGIN
                 */

                // Check if Email exists
                if (dataManager.getUserByEmail(m.login.email))
                {
                    // Check if password is a match
                    user = dataManager.getUserByEmail(m.login.email);

                    if (user.auth.password == m.login.password)
                    {
                        // Check if Email is verified
                        if (user.auth.verified)
                        {
                            // Log user in
                            // Record session info
                            user.sessions.push({time: new Date().time, id: s.id, ip: s.ip, location: s.location});

                            // Set session userId
                            s.userId = user.id;

                            // Check if user's name has been chosen
                            if (user.name != "")
                            {
                                // Let the session know it's logged in
                                s.send({loginSuccess: true});
                            }
                            else
                            {
                                // User's name has not been chosen
                                s.send({startPopup: {id: "changeName"}});
                            }
                        }
                        else
                        {
                            // Email is not verified
                            Console.log("User " + user.auth.email + "'s Email verification code is " + user.auth.verifyCode);
                            s.send({startPopup: {id: "verifyEmail", payload: m.login.email}});
                        }
                    }
                    else
                    {
                        // Password is not valid
                        s.send({startPopup: {id: "error", payload: "login"}});
                    }
                }
                else
                {
                    // User by that Email was not found
                    s.send({startPopup: {id: "error", payload: "login"}});
                }
            }

            if (m.hasOwnProperty("resendVerifyCode"))
            {
                /*
               RESEND VERIFY CODE
                */

                // Check if Email exists
                if (dataManager.getUserByEmail(m.resendVerifyCode.email))
                {
                    user = dataManager.getUserByEmail(m.resendVerifyCode.email);
                    if (!user.auth.verified)
                    {
                        // User is not verified
                        // Send the verifyCode to the user's Email
                        var emailer: Emailer = new Emailer("mail.omgforever.com", 26, "hey@omgforever.com", "KZ6kp48PREV2Z");
                        var email: String = new Service.EMAIL_VERIFY();
                        email = email.replace("%VERIFY_CODE%", user.auth.verifyCode);
                        email = email.replace("%BOTTOM_TITLE%", "Did You Know?");
                        email = email.replace("%BOTTOM_MESSAGE%", "You can view the OMG Forever changelog from within the app.");
                        emailer.send(user.auth.email, "Your Email Verification Code", email);
                    }
                    else
                    {
                        // User is verified already
                        s.send({startPopup: {id: "error", payload: "alreadyVerified"}});
                    }
                }
                else
                {
                    // User by that Email was not found
                    s.send({startPopup: {id: "error", payload: "userNotFound"}});
                }
            }

            if (m.hasOwnProperty("submitVerifyCode"))
            {
                /*
                SUBMIT VERIFY CODE
                 */

                // Check if Email exists
                if (dataManager.getUserByEmail(m.submitVerifyCode.email))
                {
                    user = dataManager.getUserByEmail(m.submitVerifyCode.email);
                    if (!user.auth.verified)
                    {
                        // User is not verified
                        if (user.auth.verifyCode == m.submitVerifyCode.verifyCode)
                        {
                            // Verify user
                            user.verified = true;

                            // Log user in
                            // Record session info
                            user.sessions.push({time: new Date().time, id: s.id, ip: s.ip, location: s.location});

                            // Set session userId
                            s.userId = user.id;

                            // Check if user's name has been chosen
                            if (user.name != "")
                            {
                                // Let the session know it's logged in
                                s.send({loginSuccess: true});
                            }
                            else
                            {
                                // User's name has not been chosen
                                s.send({startPopup: {id: "changeName", payload: "initial"}});
                            }
                        }
                        else
                        {
                            // VerifyCode is not valid
                            s.send({startPopup: {id: "error", payload: "verifyCodeNotValid"}});
                        }
                    }
                    else
                    {
                        // User is verified already
                        s.send({startPopup: {id: "error", payload: "alreadyVerified"}});
                    }
                }
                else
                {
                    // User by that Email was not found
                    s.send({startPopup: {id: "error", payload: "userNotFound"}});
                }
            }

            if (m.hasOwnProperty("changeName"))
            {
                /*
                CHANGE NAME
                 */

                user = dataManager.getUserById(m.changeName.id);
                if (s.userId == user.id)
                {
                    // Change the user's name
                    user.name = m.changeName.name;
                }
                else
                {
                    // Session is not logged in as user
                }
            }
        }

        public function sendAll(data: Object): void
        {
            // Send a message to all sessions
            for each (var s: Session in sessions)
                s.send(data);
        }

        public function sendAllUsers(data: Object): void
        {
            // Send a message to all logged in sessions
            for each (var s: Session in sessions)
                s.send(data);
        }

        public static function send(session: Session, data: Object): void
        {
            // Send a message to a specific session
            session.send(data);
        }
    }
}