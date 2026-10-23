import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// ============================================================
/// IVORY - YOUR DREAM HOUSE (CC.195)
///
/// The house dreams aloud: two hundred dreamed members - about
/// seventy parts Indian men, thirty parts Indian women, names
/// chosen to read wholly human - and a dozen deeds the house
/// longs for. A shuffle-bag deals them: no name returns until all
/// two hundred have dreamt once, and a dreamed name equal to the
/// viewing member's own is skipped at draw time, so no one ever
/// meets a ghost wearing her face.
///
/// The dream keeps its own IDs for the rotation logic; they are
/// never shown, because a shown ID would promise a person the
/// house cannot find. The dream lives in the APK and nowhere
/// else: no rows, no traffic, no cost.
/// ============================================================
class DreamShow {
  const DreamShow(this.id, this.name, this.deed);

  final int id;
  final String name;
  final String deed;
}

class DreamHouse {
  DreamHouse._();

  /// Deeds the house longs for.
  static const List<String> deeds = <String>[
    'rings the Dawn bell three hours early',
    'lit her Golden Heart tonight',
    'lit his Golden Heart tonight',
    'climbed to Tusk on the Ivory Ladder',
    'kept a letter in the Private Line',
    'opened the Ten-Day Vault on Day 1',
    'pinned a Mark to the showcase',
    'earned the Quill Door Gift',
    'left a light in the Candle Room',
    'read early, before the sun was up',
    'sent a wish upon the evening star',
    'unlocked the Laurel Door Gift',
    'cheered a ribbon and made it bloom',
    'walked in and the doorbell sang',
  ];

  /// Two hundred dreamed members. The order is the bag's seed;
  /// the dealing shuffles it.
  static const List<String> names = <String>[
    'Arjun Iyer', 'Vikram Nair', 'Rohan Menon', 'Karthik Pillai', 'Imran Qureshi',
    'Dev Reddy', 'Nikhil Rao', 'Sanjay Naidu', 'Ravi Sharma', 'Manoj Verma',
    'Ajay Gupta', 'Tarun Singh', 'Varun Yadav', 'Deepak Mishra', 'Harish Tiwari',
    'Girish Pandey', 'Farhan Sheikh', 'Zubair Ansari', 'Iqbal Khan', 'Ranjit Chatterjee',
    'Gurpreet Singh', 'Hardeep Sandhu', 'Maninder Gill', 'Satish Bansal', 'Ramesh Agarwal',
    'Suresh Iyengar', 'Dinesh Mudaliar', 'Mahesh Gowda', 'Paresh Shah', 'Naresh Mehta',
    'Anil Trivedi', 'Sunil Bhatt', 'Anup Sen', 'Biplab Dutta', 'Sourav Ghosh',
    'Abhijit Mukherjee', 'Pradipta Basu', 'Ritwick Sarkar', 'Sujoy Mandal', 'Tapan Haldar',
    'Uttam Das', 'Nirmal Saha', 'Ashok Patil', 'Prakash Deshmukh', 'Rajesh Kulkarni',
    'Yogesh Joshi', 'Mukesh Desai', 'Ganesh Shetty', 'Mahendra Bhandari', 'Jitendra Rathore',
    'Nitin Chauhan', 'Sachin Palav', 'Sandeep Tomar', 'Navdeep Dhillon', 'Kuldeep Brar',
    'Jasdeep Sidhu', 'Amarjeet Duggal', 'Balwinder Cheema', 'Sukhwinder Bajwa', 'Daljit Virk',
    'Harjit Gill', 'Manjit Sandhu', 'Surjit Sidhu', 'Shamsher Randhawa', 'Vikramjit Damania',
    'Arvinder Kohli', 'Harpreet Marwah', 'Rohit Khanna', 'Mohit Malhotra', 'Sohit Chopra',
    'Lalit Kapoor', 'Vijay Mehra', 'Ajith Kumar', 'Sujith Menon', 'Ranjith Nambiar',
    'Dileep Pillai', 'Pradeep Nair', 'Sudeep Iyer', 'Vinod Raghavan', 'Pramod Vaidya',
    'Kishore Hegde', 'Sundar Raman', 'Shankar Iyengar', 'Ravi Shankar', 'Ganeshan Subbu',
    'Murugan Selvam', 'Kannan Muthu', 'Velu Pandian', 'Senthil Arivu', 'Tamizh Selvan',
    'Kumaravel Anbu', 'Muthuraj Siva', 'Arul Prasad', 'Jeganathan Ram', 'Nagarajan Krish',
    'Subramaniam Venkat', 'Ramachandran Iyer', 'Venkatesh Rao', 'Narasimha Murthy', 'Srinivasa Raghavan',
    'Bhaskar Naidu', 'Chandra Sekhar', 'Mohana Rao', 'Pawan Deshpande', 'Mahesh Biradar',
    'Allu Bhagat', 'Naga Shastri', 'Sai Tejas', 'Uday Waghmare', 'Vamsi Karthik',
    'Gopi Nathan', 'Kalyan Joshi', 'Rana Kamat', 'Harish Shirke', 'Puri Sathe',
    'Trivikram Kulkarni', 'Sukumar Patwardhan', 'Vamsi Iyer', 'Koratala Ravi', 'Boyapati Ram',
    'Anil Gaikwad', 'Sandip Trivedi', 'Hardik Patel', 'Jignesh Thakkar', 'Mayur Dave',
    'Hiren Vora', 'Dhaval Gohil', 'Krunal Parekh', 'Hardik Vaghela', 'Rakesh Gadhvi',
    'Bhavesh Patel', 'Nilesh Modi', 'Alpesh Patel', 'Jitesh Shah', 'Maulik Desai',
    'Parth Gadhavi', 'Yash Soni', 'Tushar Trivedi', 'Sagar Meher', 'Tapan Gogoi',
    'Manab Baruah', 'Jyoti Baruah', 'Deepak Bora', 'Pranab Sarma', 'Utpal Deka',
  ];
  static const List<String> namesHer = <String>[
    'Meera Iyer', 'Lakshmi Nair', 'Anjali Menon', 'Priya Pillai', 'Kavya Reddy',
    'Divya Rao', 'Shreya Naidu', 'Pooja Sharma', 'Neha Verma', 'Sneha Gupta',
    'Ritu Singh', 'Nidhi Yadav', 'Aarti Mishra', 'Sunita Tiwari', 'Gayatri Pandey',
    'Radhika Chatterjee', 'Padma Banerjee', 'Kamala Mukherjee', 'Sushila Das', 'Anita Dutta',
    'Geeta Ghosh', 'Seema Saha', 'Rekha Sen', 'Usha Bose', 'Asha Mandal',
    'Lata Sarkar', 'Meena Haldar', 'Beena Patil', 'Heena Deshmukh', 'Priti Kulkarni',
    'Siddhi Joshi', 'Riddhi Desai', 'Trupti Mehta', 'Meghna Shah', 'Kinjal Trivedi',
    'Hetal Bhatt', 'Bhavna Thakkar', 'Nusrat Sheikh', 'Saira Ansari', 'Ayesha Khan',
    'Mariam Fernandes', 'Salma Dsouza', 'Rukhsana Ali', 'Gulnaz Begum', 'Simran Kaur',
    'Jasleen Sandhu', 'Harleen Gill', 'Gurleen Dhillon', 'Mandeep Brar', 'Navneet Bajwa',
    'Tithi Saha', 'Rimpa Mondal', 'Srabanti Dutta', 'Koel Basu', 'Moushumi Ghosh',
    'Chumki Sarkar', 'Barnali Dutta', 'Sucharita Sen', 'Nandita Das', 'Aparajita Mohanty',
  ];

  static final DreamHouse instance = DreamHouse._();

  final math.Random _rng = math.Random(20261023);
  List<int> _bag = <int>[];
  int _deedAt = 0;

  /// The viewing member's own name, so a dream never wears it.
  String viewerName = '';

  int get _total => names.length + namesHer.length;

  String _nameAt(int i) =>
      i < names.length ? names[i] : namesHer[i - names.length];

  void _refill() {
    _bag = List<int>.generate(_total, (int i) => i);
    _bag.shuffle(_rng);
  }

  /// The next dreamed member and deed, or null if the bag is empty
  /// (the caller tries again next breath).
  DreamShow? draw() {
    if (_bag.isEmpty) _refill();
    while (_bag.isNotEmpty) {
      final int i = _bag.removeLast();
      final String n = _nameAt(i);
      final String first = n.split(' ').first.toLowerCase();
      final String mine = viewerName.trim().split(' ').first.toLowerCase();
      if (mine.isNotEmpty && first == mine) continue;
      final String deed = deeds[_deedAt++ % deeds.length];
      // Her deeds for her names, his for his.
      final bool her = i >= names.length;
      String d = deed;
      if (deed.contains(' her ') && !her) d = deed.replaceFirst(' her ', ' his ');
      if (deed.contains(' his ') && her) d = deed.replaceFirst(' his ', ' her ');
      return DreamShow(i, n, d);
    }
    return null;
  }
}

/// The dream's own breath: a ribbon about every thirty seconds,
/// first one fifteen seconds after the house opens, so house and
/// dream alternate across the room.
class DreamEngine {
  DreamEngine._();

  static final DreamEngine instance = DreamEngine._();

  final ValueNotifier<DreamShow?> current = ValueNotifier<DreamShow?>(null);
  Timer? _timer;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    _timer = Timer(const Duration(seconds: 15), () {
      _beat();
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _beat());
    });
  }

  void _beat() {
    current.value = DreamHouse.instance.draw();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }
}

// END OF FILE - lib/widgets/dream_house.dart
