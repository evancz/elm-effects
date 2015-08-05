Elm.Native.Transaction = {};
Elm.Native.Transaction.make = function(localRuntime) {

	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Transaction = localRuntime.Native.Transaction || {};
	if (localRuntime.Native.Transaction.values)
	{
		return localRuntime.Native.Transaction.values;
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

	return localRuntime.Native.Transaction.values = {
		requestAnimationFrame: raf
	};

};
