
const SECONDS_IN_A_DAY: Int = 86400;
const SECONDS_IN_A_YEAR: Int = SECONDS_IN_A_DAY * 365;
const SECONDS_IN_A_LEAP_YEAR: Int = SECONDS_IN_A_DAY * 366;
struct AfterComputations{
    value: Int as uint16;
    rest: Int;
}
inline fun daysInMonth(i: Int): Int{
    if(i == 1){return 28;}
    if(i == 3){return 30;}
    if(i == 5){return 30;}
    if(i == 8){return 30;}
    if(i == 10){return 30;}
    return 31;
}
inline fun daysInLeapMonth(i: Int): Int{
    if(i == 1){
        return 29;
    }
    return daysInMonth(i);
}
inline fun getMonthFromUnixTime(timestamp: Int, year: Int): AfterComputations {

    // Determine if the given year is a leap year
    let isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);

    let month=0;
    while(month<12){
        let secondsInMonth = (isLeapYear?daysInLeapMonth(month):daysInMonth(month)) * SECONDS_IN_A_DAY;
        if (timestamp < secondsInMonth) {
            return AfterComputations{value: month + 1, rest: timestamp}; // Months are 1-based (1=January, 12=December)
        }
        timestamp -= secondsInMonth;
        month += 1;
    }
    // If the loop completes, it means we're in December
    return AfterComputations{value: 12, rest: timestamp};
}

inline fun getYearFromUnixTime(timestamp: Int): AfterComputations{
    let year = 1970;
    let breaked = false;
    let rest: Int = 0;
    let valid = true;
    while (valid) {
        // Check if the current year is a leap year
        let secondsInYear = (((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) ? SECONDS_IN_A_LEAP_YEAR : SECONDS_IN_A_YEAR);

        if (timestamp < secondsInYear) {
            rest = timestamp;
            valid = false;
        }
        else {
            timestamp -= secondsInYear;
            year = year + 1;
        }

    }
    return AfterComputations { value: year, rest};
}

inline extends fun asUnixTimeDateString(self: Int, separator: String): String{
    let dateBuilder = beginString();
    //after year computation
    let data = getYearFromUnixTime(self);
    //append year
    dateBuilder.append(data.value.toString());
    dateBuilder.append(separator);
    //calculate month
    data = getMonthFromUnixTime(data.rest, data.value);
    if(data.value < 10){
        dateBuilder.append("0");
    }
    dateBuilder.append(data.value.toString());
    dateBuilder.append(separator);
    //calculate day
    let day = data.rest / SECONDS_IN_A_DAY + 1;
    if(day < 10){
        dateBuilder.append("0");
    }
    dateBuilder.append(day.toString());
    return dateBuilder.toString();
}