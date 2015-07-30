Elm.Native.Tea = {};
Elm.Native.Tea.make = function(localRuntime) {

	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Tea = localRuntime.Native.Tea || {};
	if (localRuntime.Native.Tea.values)
	{
		return localRuntime.Native.Tea.values;
	}

	var Task = Elm.Native.Task.make(localRuntime);
	var Utils = Elm.Native.Utils.make(localRuntime);


	function raf(timeToTask)
	{
		return Task.asyncFunction(function(callback) {
			requestAnimationFrame(function(time) {
				Task.spawn(timeToTask(time));
			});
			callback(Task.succeed(Utils.Tuple0));
		});
	}

	return localRuntime.Native.Tea.values = {
		requestAnimationFrame: raf
	};

};
