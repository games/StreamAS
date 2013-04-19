package threeshooter {
	import flash.errors.IllegalOperationError;

	/**
	 * This is a port of stream.js (http://www.streamjs.org/)
	 *
	 * @author valoz
	 *
	 */
	public class Stream {

		private var headValue:*;
		private var tailPromise:Function;

		public function Stream(head:* = null, tailPromise:Function = null) {
			if (head != null)
				headValue = head;
			if (tailPromise == null)
				tailPromise = function():Stream {
					return new Stream();
				};
			this.tailPromise = tailPromise;
		}

		private function checkEmpty(message:String):void {
			if (empty)
				throw new IllegalOperationError(message);
		}

		public function get empty():Boolean {
			return headValue == null;
		}

		public function head():* {
			checkEmpty("Can't get the head of the empty Stream.");
			return headValue;
		}

		public function tail():Stream {
			checkEmpty("Can't get the tail of the empty Stream.");
			return tailPromise();
		}

		public function item(n:int):* {
			checkEmpty("Can't use item() on an empty Stream.");
			var l:Stream = this;
			while (n != 0) {
				n--;
				try {
					l = l.tail();
				} catch (e:Error) {
					throw new IllegalOperationError("Item index does not exist in Stream.");
				}
			}
			try {
				return l.head();
			} catch (e:Error) {
				throw new IllegalOperationError("Item index does not exist in Stream.");
			}
		}

		public function get length():uint {
			var l:Stream = this;
			var len:uint = 0;
			while (!l.empty) {
				len++;
				l = l.tail();
			}
			return len;
		}

		public function add(l:Stream):Stream {
			return zip(function(x, y):* {
				return x + y;
			}, l);
		}

		public function append(l:Stream):Stream {
			if (empty)
				return l;
			var self:Stream = this;
			return new Stream(self.head(), function():Stream {
				return self.tail().append(l);
			});
		}

		public function zip(f:Function, l:Stream):Stream {
			if (empty)
				return l;
			if (l.empty)
				return this;
			var self:Stream = this;
			return new Stream(f(l.head(), head()), function():Stream {
				return self.tail().zip(f, l.tail());
			});
		}

		public function map(f:Function):Stream {
			if (empty)
				return this;
			var self:Stream = this;
			return new Stream(f(head()), function():Stream {
				return self.tail().map(f);
			});
		}

		public function concatmap(f:Function):Stream {
			return reduce(function(a, x):Stream {
				return a.append(f(x));
			}, new Stream());
		}

		public function reduce(... arguments):* {
			var aggregator:* = arguments[0];
			var initial:*, self:Stream;
			if (arguments.length < 2) {
				checkEmpty("Array length is 0 and no second argument.");
				initial = head();
				self = tail();
			} else {
				initial = arguments[1];
				self = this;
			}
			if (empty)
				return initial;
			return self.tail().reduce(aggregator, aggregator(initial, self.head()));
		}

		public function sum():* {
			return reduce(function(a, b):* {
				return a + b;
			}, 0);
		}

		public function walk(f:Function):void {
			map(function(x):* {
				f(x);
				return x;
			}).force();
		}

		public function force():void {
			var l:Stream = this;
			while (!l.empty) {
				l = l.tail();
			}
		}

		public function scale(factor:Number):Stream {
			return map(function(x):* {
				return factor * x;
			});
		}

		public function filter(f:Function):Stream {
			if (empty)
				return this;
			var h:* = head();
			var t:Stream = tail();
			if (f(h))
				return new Stream(h, function():* {
					return t.filter(f);
				});
			return t.filter(f);
		}

		public function take(howmany:uint):Stream {
			if (empty)
				return this;
			if (howmany == 0)
				return new Stream();
			var self:Stream = this;
			return new Stream(head(), function():Stream {
				return self.tail().take(howmany - 1);
			});
		}

		public function drop(n:uint):Stream {
			var self:Stream = this;
			while (n-- > 0) {
				if (self.empty)
					return new Stream();
				self = self.tail();
			}
			return new Stream(self.head(), self.tailPromise);
		}

		public function member(x:*):Boolean {
			var self:Stream = this;
			while (!self.empty) {
				if (self.head() == x)
					return true;
				self = self.tail();
			}
			return false;
		}

		public function print(n:uint = 0):void {
			var target:Stream;
			if (n > 0)
				target = take(n);
			else
				target = this;
			target.walk(function(x:*):void {
				trace(x);
			});
		}

		public function array():Array {
			var arr:Array = [];
			var l:Stream = this;
			while (!l.empty) {
				arr.push(l.head());
				l = l.tail();
			}
			return arr;
		}

		public function equals(s:Stream):Boolean {
			if (empty && s.empty)
				return true;
			if (empty || s.empty)
				return false;
			if (head() === s.head())
				return tail().equals(s.tail());
			return false;
		}

		public function toString():String {
			return "[Stream head: '" + head() + "'; tail: '" + tail().toString() + "']";
		}

		public static function makeOnes():Stream {
			return new Stream(1, Stream.makeOnes);
		}

		public static function makeNaturalNumbers():Stream {
			return new Stream(1, function():Stream {
				return Stream.makeNaturalNumbers().add(Stream.makeOnes());
			});
		}

		public static function make(... arguments):Stream {
			if (arguments.length == 0)
				return new Stream();
			var restArgs:Array = arguments.slice(1);
			return new Stream(arguments[0], function():Stream {
				return Stream.make.apply(null, restArgs);
			});
		}

		public static function fromArray(array:Array):Stream {
			if (array.length == 0)
				return new Stream();
			return new Stream(array[0], function():Stream {
				return Stream.fromArray(array.slice(1));
			});
		}

		public static function range(low:uint = 0, high:uint = 0):Stream {
			if (low == high)
				return Stream.make(low);
			return new Stream(low, function():Stream {
				return Stream.range(low + 1, high);
			});
		}
	}
}
