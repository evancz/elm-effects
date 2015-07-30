Elm.Native.Components = {};
Elm.Native.Components.make = function(localRuntime) {

	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Components = localRuntime.Native.Components || {};
	if (localRuntime.Native.Components.values)
	{
		return localRuntime.Native.Components.values;
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

	return localRuntime.Native.Components.values = {
		requestAnimationFrame: raf
	};

};
