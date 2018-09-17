package
{

    import components.Console;

    import flash.events.EventDispatcher;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;

    import mx.utils.ObjectUtil;

    import mx.utils.UIDUtil;

    public final class DataManager extends EventDispatcher
    {
        private static var _instance: DataManager;
        private var data: Object;

        public function DataManager()
        {
            if (_instance)
                throw new Error("Singleton; Use getInstance() instead");
            _instance = this;
            loadDataFromFile();
        }

        public static function getInstance(): DataManager
        {
            if (!_instance)
                new DataManager();
            return _instance;
        }

        public function saveDataToFile(): void
        {
            var file: File = File.applicationStorageDirectory.resolvePath("data.json");
            var stream: FileStream = new FileStream();
            stream.open(file, FileMode.WRITE);
            stream.writeUTFBytes(JSON.stringify(data));
            stream.close();
            Console.log("Saved to " + file.nativePath, "config");
        }

        public function loadDataFromFile(): void
        {
            var file: File = File.applicationStorageDirectory.resolvePath("data.json");
            var stream: FileStream = new FileStream();
            stream.open(file, FileMode.READ);
            data = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
            stream.close();
            Console.log("Loaded from " + file.nativePath, "config");
        }

        public function getData(id: String, category: String): Object
        {
            var response: Object = (data && data[category] && data[category][id]) ? ObjectUtil.clone(data[category][id]) : null;
            if (category == "user")
            {
                // Handle permissions for user data
                if (response)
                    response.auth = null;
            }

            return response;
        }

        public function getUserByEmail(email: String): Object
        {
            for each (var user: Object in data.users)
            {
                if (user.auth.email == email)
                    return user;
            }

            return null;
        }

        public function addUser(auth: Object): void
        {
            var userKey: String = auth.betaKey;
            // Just in case a user with this key already exists, check and generate a new one
            while (data.users[userKey])
                userKey = UIDUtil.createUID();

            // Create the new user
            auth.verified = false;
            data.users[userKey] = {
                id:       userKey,
                auth:     auth,
                exp:      0,
                level:    0,
                items:    [],
                name:     "",
                sessions: []
            };

            // Delete the old key from the available beta keys
            delete data.betaKeys[auth.betaKey];
            Console.log("Registered new account\n" + auth.email);
        }

        public function addBetaKey(): String
        {
            var newKey: String = UIDUtil.createUID();
            // Make sure the key doesn't exist yet
            while (data.betaKeys[newKey])
                newKey = UIDUtil.createUID();

            data.betaKeys[newKey] = true;
            return newKey;
        }
    }
}