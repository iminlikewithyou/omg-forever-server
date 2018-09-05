package
{

    import components.Console;

    import flash.events.*;
    import flash.filesystem.*;
    import flash.net.*;

    public class Server extends EventDispatcher
    {
        private var sessions: Object;
        private var server: ServerSocket;

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

            if (m.hasOwnProperty("registerAccount"))
            {
                /*
                REGISTER
                 */

                // Check if Beta Key is valid
                if (dataManager.getData(m.registerAccount.betaKey, "betaKeys"))
                {
                    // Check if Email is valid
                    if (Service.isValidEmail(m.registerAccount.email))
                    {
                        //Check if Email is not already used
                        if (!dataManager.getUserByEmail(m.registerAccount.email))
                        {
                            dataManager.addUser(m.registerAccount);
                            s.send({"login": {"email": m.registerAccount.email, "hash": m.registerAccount.hash, "password": m.registerAccount.password}});
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