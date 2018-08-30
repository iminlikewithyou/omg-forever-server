package
{

    import components.Console;

    import flash.events.EventDispatcher;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;

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
            Console.log("Data saved to " + file.nativePath, "config");
        }

        public function loadDataFromFile(): void
        {
            var file: File = File.applicationStorageDirectory.resolvePath("data.json");
            var stream: FileStream = new FileStream();
            stream.open(file, FileMode.READ);
            data = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
            stream.close();
            Console.log("Data loaded from " + file.nativePath, "config");
        }

        public function getData(id: String, category: String): Object
        {
            return (data && data.category && data.category.id) ? data.category.id : null;
        }
    }
}
