import ceylon.file {
    ...
}

Integer successExitCode = 0;

Integer noArgumentsExitCode = 1;

Integer fileNameIsDirectoryExitCode = 2;

Integer fileDoesNotExistsExitCode = 3;

Integer unknownErrorExitCode = 4;

String usage = """
                  Usage: expression file
                  """;


shared void run() {

    try {
        value [exitCode, message] = processFile(process.arguments);
        exitProcess(exitCode, message);

    } catch (Exception|AssertionError error) {
        exitProcess(unknownErrorExitCode, "Error: ``error.message``");
    }

}

[Integer, String?] processFile(String[] arguments) {

    if (process.arguments.empty) {
        return [noArgumentsExitCode, usage];
    }

    value fileName = process.arguments.first;

    assert (exists fileName);

    value file = parsePath(fileName).resource.linkedResource;

    switch (file)
    case (is File) {
        Integer exitCode = evaluateFile(file);
        return [exitCode, null];
    }
    case (is Directory) {
        return [fileNameIsDirectoryExitCode, "``file.string``: is a Directory "];
    }
    case (is Nil) {
        return [fileDoesNotExistsExitCode, "``file.string``: no such file."];
    }

}

suppressWarnings ("expressionTypeNothing")
void exitProcess(Integer exitCode, String? message = null) {
    if (exists message) {
        print(message);
    }

    process.exit(exitCode);
}

Integer evaluateFile(File file) {
    print(file.path.absolutePath.uriString);

    value expressions = lines(file);

    expressions.each(print);

    return successExitCode;
}