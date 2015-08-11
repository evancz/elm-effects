Elm.Native.Effects = {};
Elm.Native.Effects.make = function(localRuntime) {

	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Effects = localRuntime.Native.Effects || {};
	if (localRuntime.Native.Effects.values)
	{
		return localRuntime.Native.Effects.values;
	}

	var Task = Elm.Native.Task.make(localRuntime);
	var Utils = Elm.Native.Utils.make(localRuntime);


	function raf(timeToTask)
	{
		return Task.asyncFunction(function(callback) {
			requestAnimationFrame(function(time) {
				Task.perform(timeToTask(time));
			});
			callback(Task.succeed(Utils.Tuple0));
		});
	}

	return localRuntime.Native.Effects.values = {
		requestAnimationFrame: raf
	};

};
