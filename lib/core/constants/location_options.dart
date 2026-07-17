class LocationOptions {
  static const List<String> states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Tamil Nadu',
    'Telangana',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  static const Map<String, List<String>> districtsByState = {
    'Bihar': ['Patna', 'Gaya', 'Muzaffarpur', 'Bhagalpur', 'Purnia'],
    'Chhattisgarh': ['Raipur', 'Bilaspur', 'Durg', 'Bastar', 'Korba'],
    'Himachal Pradesh': ['Shimla', 'Kangra', 'Mandi', 'Kullu', 'Solan'],
    'Karnataka': ['Bengaluru Urban', 'Mysuru', 'Mangaluru', 'Hubballi', 'Belagavi'],
    'Kerala': ['Kozhikode', 'Thiruvananthapuram', 'Ernakulam', 'Thrissur', 'Kollam'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Barmer'],
    'West Bengal': ['Kolkata', 'Darjeeling', 'Howrah', 'Siliguri', 'Malda'],
  };

  static List<String> districtsFor(String? state) {
    if (state == null || state.isEmpty) return const [];
    return districtsByState[state] ?? const [];
  }
}
