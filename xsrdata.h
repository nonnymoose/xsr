/* requres the following includes
string
list
queue
mutex
condition_variable
X11/Xlib.h
*/

class XSRPress { // can hold keypress or mouse press; if it holds a mouse press but isModifier is true, it should be treated as a keypress (see TODO for more information)
	public:
		std::string description;
		bool isModifier;
		XSRPress(std::string description_, bool isModifier_) : description(description_), isModifier(isModifier_) {}
};

enum class XSRDataType {
	typing,
	click,
	drag,
	EXIT
};

class XSRData {
	private:
		XImage *screenshot_;
		XSRDataType type_;
	public:
		XImage* screenshot() {
			return screenshot_;
		}
		XSRDataType type() {
			return type_;
		}
		std::list<XSRPress> presses;
		XSRData() : screenshot_((XImage*)nullptr), type_(XSRDataType::typing) {}
		XSRData(XImage *screenshot__, XSRDataType type__) : screenshot_(screenshot__), type_(type__) {}
		XSRData(XImage *screenshot__, std::list<XSRPress>&& presses_, XSRDataType type__) : screenshot_(screenshot__), type_(type__), presses(presses_) {} // constructing with presses must move data
		friend void swap(XSRData& one, XSRData& two) {
			using std::swap;
			swap(one.screenshot_, two.screenshot_);
			swap(one.type_, two.type_);
			swap(one.presses, two.presses);
		}
		XSRData& operator=(XSRData other) {
			swap(*this, other);
			return *this;
		}
		XSRData(XSRData&& other) : XSRData() {
			swap(*this, other);
		}
};

extern std::queue<XSRData> XSRDataQueue;
extern std::mutex XSRDataQueueMutex;
extern std::condition_variable XSRDataAvailable;
extern bool XSRDataAvailableBoolean;
