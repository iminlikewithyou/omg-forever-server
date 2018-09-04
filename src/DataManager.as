package
{

    import components.Console;

    import flash.events.EventDispatcher;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;

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
            var response: Object = (data && data[category] && data[category][id]) ? data[category][id] : null;
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

        public function addUser(userObject: Object): void
        {
            Console.log("Adding new user ...\n" + JSON.stringify(userObject));
        }

        public function addBetaKey():String {
            var newKey:String = UIDUtil.createUID();
            data.betaKeys[newKey] = true;
            return newKey;
        }
    }
}