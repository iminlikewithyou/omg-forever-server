package
{

    import components.Console;

    import flash.events.*;
    import flash.filesystem.*;
    import flash.net.*;

    import mx.utils.UIDUtil;

    public class Server extends EventDispatcher
    {
        private var sessions: Object;
        private var server: ServerSocket;

        // Data
        private var userNameIdPairs: Object;
        private var users: Object;
        private var rooms: Object;

        public function Server(): void
        {
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

            // TODO Populate users from data (UserVO)
            users = {};

            // TODO Populate rooms from data (RoomVO)
            rooms = {};

            // Sessions start empty
            sessions = {};

            // Start the server
            server = new ServerSocket();
            server.bind(Service.PORT);
            server.addEventListener(ServerSocketConnectEvent.CONNECT, handleConnect);
            server.listen();
            Console.log("Server started on port " + Service.PORT);
        }

        private function handleConnect(e: ServerSocketConnectEvent): void
        {
            // When a Socket connects
            var session: Session = new Session(e.socket);
            sessions[session.id] = session;

            // Session event listeners
            session.addEventListener(Session.DISCONNECT, handleDisconnect);
            session.addEventListener(MessageEvent.DATA, handleDataReceived);

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
            var user: UserVO;

            // Handle messages from all sessions, whether or not they are logged in
            switch (m.type)
            {
                case "register":
                    // Register a user
                    if (!userIdFromName(m.name))
                    {
                        // Register pass
                        Console.log("User " + m.name + " registered");
                        addUser(m.name, {password: m.password});
                        send(s, {type: "register", message: "pass"});
                    }
                    else
                    {
                        // Register fail
                        Console.log("User " + m.name + " couldn't be registered");
                        send(s, {type: "register", message: "fail", reason: "nameAlreadyExists"});
                    }
                    break;
                case "login":
                    // Login a user
                    user = users[userIdFromName(m.name)];
                    if ((user) && (user.password == m.password) && (!user.online))
                    {
                        if (user.emailVerified)
                        {
                            // Login pass (Email is verified)
                            Console.log("User " + user.name + " logged in");
                            user.online = true;
                            send(s, {type: "login", message: "pass"});
                        }
                        else
                        {
                            // Login fail (Email isn't verified)
                            Console.log("User " + user.name + " couldn't log in (needs verification)");
                            send(s, {type: "login", message: "fail", reason: "verify"});
                        }
                    }
                    else
                    {
                        // Login fail
                        Console.log("User " + user.name + " couldn't log in");
                        send(s, {type: "login", message: "fail", reason: "auth"});
                    }
                    break;
                case "verify":
                    // Verify a user
                    user = users[userIdFromName(m.name)];
                    if ((user) && (user.emailVerificationCode == m.emailVerificationCode))
                    {
                        // Verify pass
                        Console.log("User " + user.name + " was verified");
                        user.emailVerified = true;
                        send(s, {type: "verify", message: "pass"});
                    }
                    else
                    {
                        // Verify fail
                        Console.log("User " + m.name + " couldn't be verified");
                        send(s, {type: "verify", message: "fail"});
                    }
                    break;
                case "verifyResend":
                    Console.log("A verifyCode for " + m.name + " was requested");
                    user = users[userIdFromName(m.name)];
                    if (user)
                    {
                        // Create a new email verification code
                        user.emailVerificationCode = UIDUtil.createUID();
                        Console.log("New emailVerificationCode is " + user.emailVerificationCode);
                        var verifyEmailer: Emailer = new Emailer("mail.omgforever.com", 26, "verify@omgforever.com", "OMG4ever");
                        verifyEmailer.send(user.email, "Verify your Email Address", (Service.EMAIL_VERIFY as String).replace("%VERIFICATION_CODE%", user.emailVerificationCode));
                    }
                    else
                    {
                        Console.log("User " + m.name + " doesn't exist");
                    }
                    break;
                case "reset":
                    // Attempt to reset a user's password
                    user = users[userIdFromName(m.name)];
                    if ((user) && user.passwordResetCode && user.passwordResetCode == m.passwordResetCode)
                    {
                        // Password reset true
                        user.password = m.password;
                        user.passwordResetCode = null;
                        Console.log("User " + user.name + "\'s password was reset");
                        send(s, {type: "reset", message: "pass"});
                    }
                    else
                    {
                        // Password reset fail
                        Console.log("User " + m.name + " couldn't reset their password");
                        send(s, {type: "reset", message: "fail"});
                    }
                    break;
                case "resetResend":
                    // Send a resetCode to a user's Email
                    Console.log("A resetCode for " + m.name + " was requested");
                    user = users[userIdFromName(m.name)];
                    if (user)
                    {
                        user.passwordResetCode = Service.generateRandomString(6);
                        Console.log("New resetCode is " + user.passwordResetCode);
                        var resetEmailer: Emailer = new Emailer("mail.omgforever.com", 26, "support@omgforever.com", "OMG4ever");
                        resetEmailer.send(user.name, "Password Change Request", (Service.EMAIL_RESET as String).replace("%NAME%", m.name).replace("%RESET_CODE%", user.passwordResetCode));
                    }
                    else
                    {
                        Console.log("User doesn't exist");
                    }
                    break;
                default:
                    break;
            }

            // Handle messages from only logged in sessions
            //if (s.name)
            //{
            //    switch (m.type)
            //    {
            //        case "users":
            //            // Session requests users for a user
            //            if (!m.target)
            //                m.target = s.name;
            //            if (permission(s.name, m.target))
            //            {
            //                // TODO send target data instead of sender's data...?!
            //                // Never include auth in users
            //                var usersToSend: Object = {};
            //                for (var k: String in users[s.name])
            //                    if (k != "auth")
            //                        usersToSend[k] = users[s.name][k];
            //
            //                usersToSend["self"] = (s.name == m.target);
            //
            //                send(s, {type: "users", message: "pass", data: usersToSend});
            //            }
            //            else
            //            {
            //                send(s, {type: "users", message: "fail"});
            //            }
            //            break;
            //        case "nameChange":
            //            // Attempt to set a user's nick
            //            Console.log("A nameChange for " + s.name + " was requested");
            //            var exists: Boolean = false;
            //            for (var key: String in users)
            //            {
            //                if (users[key]["nick"] == m.message)
            //                {
            //                    exists = true;
            //                    break;
            //                }
            //            }
            //
            //            if (!exists && users[s.name] && !users[s.name]["nick"] && Service.isValid(m.message, "nick"))
            //            {
            //                // Name change pass
            //                Console.log("User " + s.name + " changed their name from " + users[s.name]["nick"] + " to " + m.message);
            //                users[s.name]["nick"] = m.message;
            //                send(s, {type: "nameChange", message: "pass"});
            //            }
            //            else
            //            {
            //                // Name change fail
            //                Console.log("User " + s.name + " couldn't change their name");
            //                send(s, {type: "nameChange", message: "fail"});
            //            }
            //            break;
            //        case "logout":
            //            // Logout the current session
            //            Console.log("User " + s.name + " logged out");
            //            users[s.name].online = false;
            //            s.name = null;
            //            send(s, {type: "logout", message: "pass"});
            //            break;
            //        case "claimRewards":
            //            // Claims all current rewards
            //            Console.log("User " + s.name + " claims " + users[s.name].rewards.length);
            //            // Unpackage all rewards and send an update to the user
            //            break;
            //        default:
            //            break;
            //    }
            //}
        }

        private function userIdFromName(name: String): String
        {
            if (!userNameIdPairs)
                userNameIdPairs = {};

            if (!userNameIdPairs[name])
            {
                for each (var user: UserVO in users)
                {
                    if (user.name == name)
                    {
                        userNameIdPairs[name] = user.id;
                        break;
                    }
                }
            }

            return userNameIdPairs[name];
        }

        public function save(): void
        {
            // Save userData
            var file: File = File.applicationStorageDirectory.resolvePath("data.json");
            var fileStream: FileStream = new FileStream();
            fileStream.open(file, FileMode.WRITE);
            //TODO Save user and room data
            //fileStream.writeUTFBytes(JSON.stringify(users[name]));
            fileStream.close();
        }

        private function addUser(name: String, auth: Object): void
        {
            // Register a new user to users
            //auth["emailVerified"] = false;
            //auth["emailVerificationCode"] = Service.generateKey(1);
            //
            //if (Service.CLOSED_ALPHA)
            //    delete keys[auth.alphaKey];
            //
            //users[name] = {name: name, auth: auth, online: false, timeCreated: new Date().time, nick: null};
            //prepusers(name);
            //
            //var verifyEmailer: Emailer = new Emailer("mail.omgforever.com", 26, "verify@omgforever.com", "OMG4ever");
            //verifyEmailer.send(name, "Verify your Email Address", verifyEmail.replace("%VERIFICATION_CODE%", auth.emailVerificationCode));
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

        public function send(session: Session, data: Object): void
        {
            // Send a message to a specific session
            session.send(data);
        }
    }
}