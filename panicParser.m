//clang -fmodules ./panicParser.m -o ./panicParser
@import Foundation;

void writePanicToFile(NSString *stackTrace,NSString *other,NSArray *arguments){
	//write panic to file
	NSLog(@"Writing panic to file...");
	BOOL didWrite = [[NSString stringWithFormat:@"%@%@",stackTrace,other] writeToFile:[arguments objectAtIndex:3] atomically:YES];
	
	//confirm it wrote successfully
	if(!didWrite){
		NSLog(@"did not write successfully");
	} else {
		NSLog(@"Panic written successfully!");
	}
}

NSString *formatPanic(NSString *panicContents){
	//formatting is interpretted really weirdly, no clue why
	panicContents = [panicContents stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
	panicContents = [panicContents stringByReplacingOccurrencesOfString:@"\\t" withString:@"\t"];
	panicContents = [panicContents stringByReplacingOccurrencesOfString:@"\\" withString:@""];
		
	return panicContents;
}

NSString *handleStackTrace(NSString *panicContents){
	//get *only* the base64 stacktrace
	NSString *stackTracePre = [panicContents componentsSeparatedByString:@"\",\"notes"].firstObject;
	NSString *stackTracePost = [stackTracePre componentsSeparatedByString:@"{\"macOSProcessedStackshotData\":\""].lastObject;
	
	//decode said stacktrace	
	NSData *decodedTrace = [[NSData alloc] initWithBase64EncodedString:stackTracePost options:0];
	NSString *stackTrace = [[NSString alloc] initWithData:decodedTrace encoding:NSUTF8StringEncoding];
	
	//return stacktrace
	return stackTrace;
}

NSString *handleOther(NSString *panicContents){
	//get the non-stacktrace part of log
	NSString *otherPre = [panicContents componentsSeparatedByString:@"macOSPanicString\":\""].lastObject;
	return otherPre;
}

NSString *getPanicContents(NSArray *args){
	//NSString *panicPath = [[NSBundle mainBundle] pathForResource:@"panic" ofType:@"panic"];

	//capture any possible errors
	NSError *panicError;
	
	//make sure the directory actually exists
	if(![[NSFileManager defaultManager] fileExistsAtPath:[args objectAtIndex:1]]){
		NSLog(@"you are dumb, specify an actual panic log. this doesn't even exist");
		exit(0);
	}
	
	//get contents from first argument
	NSString *panicContents = [NSString stringWithContentsOfFile:[args objectAtIndex:1] encoding:NSUTF8StringEncoding error:&panicError];
	

	//log an error, if any
	return formatPanic(panicContents);
}

void printPanic(NSArray *arguments){
	//define panicContents just to make it look pretty
	NSString *panicContents = getPanicContents(arguments);

	//print parts of panic
	NSLog(@"\n%@\n%@",handleStackTrace(panicContents),handleOther(panicContents));
	
}

void checkSyntax(NSArray *arguments){
	//if there aren't any specified arguments
	if(arguments.count == 1){
		NSLog(@"Not enough arguments specified. Run with '-h' for help");
		exit(0);
	} else if([arguments[1] isEqualToString:@"-h"]){ //if help is required
		NSLog(@"\nOutput Panic Log To Terminal:\nparsePanic (input file)\nOutput Panic Log To File:\nparsePanic (input file) writeToFile (output file)");
		exit(0);
	} else if(arguments.count < 4 && arguments.count > 2 && [arguments[2] containsString:@"writeToFile"]){ //if writeToFile was specified, but still not enough arguments
		NSLog(@"Not enough arguments specified. Run with '-h' for help");
		exit(0);
	}
}

int main(){	
	//get arguments of program
	NSArray *arguments = [[NSProcessInfo processInfo] arguments];	
	
	//make sure arguments specified aren't stupid
	checkSyntax(arguments);
	
	//raw contents of panic log
	NSString *panicContents = getPanicContents(arguments);

	//just print, or save panic?
	if([arguments containsObject:@"writeToFile"]){
		writePanicToFile(handleStackTrace(panicContents),handleOther(panicContents),arguments);
	} else {
		printPanic(arguments);
	}

	return 0;
}