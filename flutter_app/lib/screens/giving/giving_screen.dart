import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';

class GivingScreen extends StatefulWidget {
  const GivingScreen({super.key});

  @override
  State<GivingScreen> createState() => _GivingScreenState();
}

class _GivingScreenState extends State<GivingScreen>
    with TickerProviderStateMixin {
  static final Logger _logger = Logger();
  late TabController _tabController;

  final List<GivingMethod> _givingMethods = [
    // Global methods (available to all branches)
    GivingMethod(
      title: 'Bank Account Transfer',
      description: 'Transfer directly to our church bank account',
      icon: Icons.account_balance,
      accountDetails:
          'Bank Name: Equity Bank Uganda\n'
          'Account Name: Divine Life Ministries International\n'
          'Account Number: 1014101000123456\n'
          'Swift Code: EQBLUGKA\n'
          'Currency: UGX',
      color: Colors.blue,
      features: ['Bank Transfer', 'Swift Code Available', 'UGX Currency'],
      branchId: null, // Global method
    ),
    GivingMethod(
      title: 'Airtel Money',
      description: 'Send money using Airtel Money mobile service',
      icon: Icons.phone_android,
      accountDetails:
          'Service: Airtel Money\n'
          'Merchant Code: 4382082\n'
          'Account Name: Divine Life Ministries International\n'
          'Phone: +256775687262\n'
          'Currency: UGX',
      color: Colors.red,
      features: ['Mobile Money', 'Instant Transfer', '24/7 Available'],
      branchId: null, // Global method
    ),
    GivingMethod(
      title: 'MTN Mobile Money',
      description: 'Send money using MTN Mobile Money service',
      icon: Icons.smartphone,
      accountDetails:
          'Service: MTN Mobile Money\n'
          'Merchant Code: 752453\n'
          'Account Name: Divine Life Ministries International\n'
          'Phone: +256775687262\n'
          'Currency: UGX',
      color: Colors.yellow.shade700,
      features: ['Mobile Money', 'Instant Transfer', '24/7 Available'],
      branchId: null, // Global method
    ),
  ];

  final List<GivingCategory> _givingCategories = [
    GivingCategory(
      title: 'Tithe',
      description:
          'This is the ten percent of your income, it has to be first removed before',
      icon: Icons
          .account_balance_wallet, // Represents financial stewardship and the 10% principle
      color: Colors.blue,
      percentage: 40,
    ),
    GivingCategory(
      title: 'First Fruit',
      description: 'The first increase of your income offered to God',
      icon: Icons
          .agriculture, // Represents agricultural first fruits and harvest offerings
      color: Colors.green,
      percentage: 25,
    ),
    GivingCategory(
      title: 'Offertory',
      description: 'This is your freewill offering given to the church',
      icon: Icons
          .pan_tool, // Represents the act of giving/offering with open hands
      color: Colors.purple,
      percentage: 15,
    ),
    GivingCategory(
      title: 'Building Fund',
      description:
          'This goes directly to church infrastructure and maintenance',
      icon: Icons.construction,
      color: Colors.orange,
      percentage: 10,
    ),
    GivingCategory(
      title: 'Education Fund',
      description:
          'This goes to our education account which we use to support our children\'s education',
      icon: Icons.school,
      color: Colors.blue,
      percentage: 5,
    ),
    GivingCategory(
      title: 'Community Outreach and Anagkazo',
      description: 'This helps in evangelism and supporting those in need',
      icon: Icons.volunteer_activism,
      color: Colors.teal,
      percentage: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    ); // Reduced from 3 to 2 (Impact tab commented out)
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Giving'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            actions: [
              if (authProvider.canManageGiving)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showManageGivingDialog,
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Give Now', icon: Icon(Icons.favorite)),
                Tab(text: 'Ways to Give', icon: Icon(Icons.payment)),
                // Tab(text: 'Impact', icon: Icon(Icons.trending_up)), // Commented out for future use
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildGiveNowTab(),
              _buildWaysToGiveTab(),
              // _buildImpactTab(), // Commented out for future use
            ],
          ),
        );
      },
    );
  }

  Widget _buildGiveNowTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.favorite,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Generosity Makes a Difference',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '"So let each one give as he purposes in his heart, not grudgingly or of necessity, for God loves a cheerful giver." - 2 Corinthians 9:7',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Quick Give Amounts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Give',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [50000, 100000, 200000, 500000].map((amount) {
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 80) / 3,
                      child: ElevatedButton(
                        onPressed: () => _quickGive(amount),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'UGX $amount',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _customAmountGive(),
                    icon: const Icon(Icons.edit),
                    label: const Text('Enter Custom Amount'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Mobile Money Quick Access
                Text(
                  'Mobile Money Quick Access',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Airtel Money Card
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.phone_android, color: Colors.red),
                    ),
                    title: const Text(
                      'Airtel Money Pay',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Merchant Code: 4382082'),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(
                        '4382082',
                        'Airtel Money merchant code copied!',
                      ),
                    ),
                  ),
                ),

                // MTN Mobile Money Card
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade700.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.smartphone,
                        color: Colors.yellow.shade700,
                      ),
                    ),
                    title: const Text(
                      'MTN Mobile Money',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Merchant Code: 752453'),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(
                        '752453',
                        'MTN Mobile Money merchant code copied!',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Giving Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giving Categories',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...(_givingCategories.map((category) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: category.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(category.icon, color: category.color),
                        ),
                        title: Text(
                          category.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category.description),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: category.percentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation(
                                category.color,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${category.percentage}%',
                          style: TextStyle(
                            color: category.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList()),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWaysToGiveTab() {
    final visibleMethods = _getVisibleGivingMethods();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Choose Your Preferred Giving Method',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ...visibleMethods.map((method) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 4,
                child: InkWell(
                  onTap: method.url != null
                      ? () => _launchUrl(method.url!)
                      : method.accountDetails != null
                      ? () => _showAccountDetails(method)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          method.color.withValues(alpha: 0.1),
                          method.color.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: method.color.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: method.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                method.icon,
                                color: method.color,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    method.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    method.description,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              method.url != null ||
                                      method.accountDetails != null
                                  ? Icons.arrow_forward_ios
                                  : Icons.info_outline,
                              color: method.color,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: method.features.map((feature) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: method.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                feature,
                                style: TextStyle(
                                  color: method.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        // Add visual hint for interaction
                        if (method.accountDetails != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: method.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: method.color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  size: 14,
                                  color: method.color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Tap to view payment details',
                                  style: TextStyle(
                                    color: method.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // TODO: Future Implementation - Impact Tab
  // Commented out for now, will be used in future
  /*
  Widget _buildImpactTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Impact This Year',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Impact Statistics
            Row(
              children: [
                Expanded(
                  child: _buildImpactCard(
                    'Families Helped',
                    '450+',
                    Icons.family_restroom,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImpactCard(
                    'Meals Provided',
                    '12K+',
                    Icons.restaurant,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildImpactCard(
                    'Children Educated',
                    '200+',
                    Icons.school,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImpactCard(
                    'Missionaries Supported',
                    '15',
                    Icons.public,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Testimonials
            Text(
              'Stories of Impact',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildTestimonialCard(
              '"Thanks to the church\'s support, my family received food during our difficult time. Your generosity truly saved us."',
              'Sarah M.',
              'Local Community Member',
            ),

            _buildTestimonialCard(
              '"The youth program funded by your donations changed my son\'s life. He now has direction and purpose."',
              'Michael T.',
              'Parent',
            ),

            _buildTestimonialCard(
              '"Through the mission fund, we were able to build a school in Uganda. 150 children now have access to education."',
              'Pastor James K.',
              'Missionary',
            ),

            const SizedBox(height: 32),

            // Thank You Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.volunteer_activism,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Thank You!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your faithful giving enables us to continue God\'s work in our community and beyond. Every gift, no matter the size, makes a lasting impact.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  */

  // TODO: Future Implementation - Impact Card Widget
  // Commented out for now, will be used in future with Impact tab
  /*
  Widget _buildImpactCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
  */

  // TODO: Future Implementation - Testimonial Card Widget
  // Commented out for now, will be used in future with Impact tab
  /*
  Widget _buildTestimonialCard(String quote, String name, String role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.format_quote,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              quote,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    name[0],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(role, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  */

  void _quickGive(int amount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Give UGX ${amount.toString()}'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How would you like to give this amount?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Choose your preferred payment method below:',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showMobileMoneyInstructions(amount.toString());
              },
              icon: const Icon(Icons.phone_android),
              label: const Text('Mobile Money'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showBankTransferInstructions(amount.toString());
              },
              icon: const Icon(Icons.account_balance),
              label: const Text('Bank Transfer'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        );
      },
    );
  }

  void _customAmountGive() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController amountController = TextEditingController();
        return AlertDialog(
          title: const Text('How would you like to give?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Amount (UGX)',
                  prefixText: 'UGX ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose your payment method:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final amount = amountController.text;
                if (amount.isNotEmpty) {
                  Navigator.of(context).pop();
                  _showMobileMoneyInstructions(amount);
                }
              },
              icon: const Icon(Icons.phone_android),
              label: const Text('Mobile Money'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final amount = amountController.text;
                if (amount.isNotEmpty) {
                  Navigator.of(context).pop();
                  _showBankTransferInstructions(amount);
                }
              },
              icon: const Icon(Icons.account_balance),
              label: const Text('Bank Transfer'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        );
      },
    );
  }

  void _showMobileMoneyInstructions(String amount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mobile Money - UGX $amount'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Follow these steps to complete your giving:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Airtel Money Instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_android, color: Colors.red),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Airtel Money Pay',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copyToClipboard(
                              '4382082',
                              'Airtel merchant code copied!',
                            ),
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: 'Copy Merchant Code',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const Text('1. Dial *185*9#'),
                      const Text('2. Enter Merchant Code: 4382082'),
                      Text('3. Enter Amount: UGX $amount'),
                      const Text('4. Follow prompts to complete'),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // MTN Mobile Money Instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade700.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.yellow.shade700.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.smartphone, color: Colors.yellow.shade700),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'MTN Mobile Money',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copyToClipboard(
                              '752453',
                              'MTN merchant code copied!',
                            ),
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: 'Copy Merchant Code',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const Text('1. Dial *165*3#'),
                      const Text('2. Enter Merchant Code: 752453'),
                      Text('3. Enter Amount: UGX $amount'),
                      const Text('4. Follow prompts to complete'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showBankTransferInstructions(String amount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Bank Transfer - UGX $amount'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Use these details for your bank transfer:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bank Name: Equity Bank Uganda',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Text(
                        'Account Name: Divine Life Ministries International',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Account Number: 1014101000123456',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copyToClipboard(
                              '1014101000123456',
                              'Account number copied!',
                            ),
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: 'Copy Account Number',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const Text(
                        'Swift Code: EQBLUGKA',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Amount: UGX $amount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please include your name in the transfer reference for proper recording.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                const bankDetails =
                    'Bank: Equity Bank Uganda\n'
                    'Account: Divine Life Church\n'
                    'Number: 1014101000123456\n'
                    'Swift: EQBLUGKA';
                _copyToClipboard(bankDetails, 'All bank details copied!');
              },
              child: const Text('Copy All Details'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAccountDetails(GivingMethod method) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(method.icon, color: method.color),
              const SizedBox(width: 8),
              Expanded(child: Text(method.title)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),

                // Highlighted account details section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: method.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: method.color.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: method.color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Payment Details',
                            style: TextStyle(
                              color: method.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        method.accountDetails ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Colors.amber),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tap "Copy Details" to copy all information to your clipboard, then paste into your banking app.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                String toCopy = '';
                if (method.title.toLowerCase().contains('bank')) {
                  final match = RegExp(
                    r'Account Number: ([^\n]+)',
                  ).firstMatch(method.accountDetails ?? '');
                  toCopy = match != null ? match.group(1) ?? '' : '';
                } else if (method.title.toLowerCase().contains('airtel') ||
                    method.title.toLowerCase().contains('mtn')) {
                  final match = RegExp(
                    r'Merchant Code: ([^\n]+)',
                  ).firstMatch(method.accountDetails ?? '');
                  toCopy = match != null ? match.group(1) ?? '' : '';
                }
                if (toCopy.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: toCopy));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        method.title.toLowerCase().contains('bank')
                            ? 'Account number copied to clipboard!'
                            : 'Merchant code copied to clipboard!',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: Text(
                method.title.toLowerCase().contains('bank')
                    ? 'Copy Account Number'
                    : 'Copy Merchant Code',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: method.color,
                side: BorderSide(color: method.color),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not open $url');
      }
    } catch (e) {
      _logger.e('Error launching URL $url: $e');
      _showErrorSnackBar('Error opening link: $e');
    }
  }

  List<GivingMethod> _getVisibleGivingMethods() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userBranchId = authProvider.userBranchId;

    // Users see global methods and methods for their branch
    return _givingMethods.where((method) {
      return method.branchId == null || method.branchId == userBranchId;
    }).toList();
  }

  List<GivingMethod> _getManageableGivingMethods() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isSuperAdmin) {
      // Super admins can manage all methods
      return _givingMethods;
    } else if (authProvider.isBranchAdmin) {
      // Branch admins can only manage global methods and their branch methods
      final userBranchId = authProvider.userBranchId;
      return _givingMethods.where((method) {
        return method.branchId == null || method.branchId == userBranchId;
      }).toList();
    }

    // Non-admin users cannot manage any methods
    return [];
  }

  void _showManageGivingDialog() {
    final manageableMethods = _getManageableGivingMethods();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            authProvider.isSuperAdmin
                ? 'Manage Giving Methods (All Branches)'
                : 'Manage Giving Methods (Your Branch)',
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: manageableMethods.isEmpty
                ? const Center(child: Text('No methods available to manage'))
                : ListView.builder(
                    itemCount: manageableMethods.length,
                    itemBuilder: (context, index) {
                      final method = manageableMethods[index];
                      final actualIndex = _givingMethods.indexOf(method);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(method.icon, color: method.color),
                          title: Row(
                            children: [
                              Expanded(child: Text(method.title)),
                              if (method.branchId == null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'GLOBAL',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(method.description),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editGivingMethod(actualIndex),
                              ),
                              if (_canDeleteMethod(method))
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _deleteGivingMethod(actualIndex),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: _addNewGivingMethod,
              child: const Text('Add Method'),
            ),
          ],
        );
      },
    );
  }

  bool _canDeleteMethod(GivingMethod method) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Super admins can delete any method
    if (authProvider.isSuperAdmin) return true;

    // Branch admins can delete their branch methods but not global methods
    if (authProvider.isBranchAdmin) {
      return method.branchId == authProvider.userBranchId;
    }

    return false;
  }

  void _editGivingMethod(int index) {
    final method = _givingMethods[index];
    _showGivingEditDialog(method, index);
  }

  void _addNewGivingMethod() {
    _showGivingEditDialog(null, null);
  }

  void _showGivingEditDialog(GivingMethod? method, int? index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final titleController = TextEditingController(text: method?.title ?? '');
    final descriptionController = TextEditingController(
      text: method?.description ?? '',
    );
    final urlController = TextEditingController(text: method?.url ?? '');
    final accountController = TextEditingController(
      text: method?.accountDetails ?? '',
    );
    final featuresController = TextEditingController(
      text: method?.features.join(', ') ?? '',
    );
    IconData selectedIcon = method?.icon ?? Icons.credit_card;
    Color selectedColor = method?.color ?? Colors.blue;

    // Branch scope selection
    int? selectedBranchId =
        method?.branchId ??
        (authProvider.isSuperAdmin ? null : authProvider.userBranchId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                method == null ? 'Add Giving Method' : 'Edit Giving Method',
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: urlController,
                        decoration: const InputDecoration(
                          labelText: 'URL (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: accountController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Account Details (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: featuresController,
                        decoration: const InputDecoration(
                          labelText: 'Features (comma separated)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Icon: ${selectedIcon.codePoint}'),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                _showIconPicker(setDialogState, (icon) {
                                  selectedIcon = icon;
                                }),
                            child: const Text('Choose Icon'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              color: selectedColor,
                              child: const Center(
                                child: Text(
                                  'Color',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () =>
                                _showColorPicker(setDialogState, (color) {
                                  selectedColor = color;
                                }),
                            child: const Text('Choose Color'),
                          ),
                        ],
                      ),
                      if (authProvider.isSuperAdmin) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int?>(
                          initialValue: selectedBranchId,
                          decoration: const InputDecoration(
                            labelText: 'Branch Scope',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Global (All Branches)'),
                            ),
                            const DropdownMenuItem<int?>(
                              value: 1,
                              child: Text('Branch 1 - Main Campus'),
                            ),
                            const DropdownMenuItem<int?>(
                              value: 2,
                              child: Text('Branch 2 - North Campus'),
                            ),
                            const DropdownMenuItem<int?>(
                              value: 3,
                              child: Text('Branch 3 - South Campus'),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedBranchId = value;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newMethod = GivingMethod(
                      title: titleController.text,
                      description: descriptionController.text,
                      icon: selectedIcon,
                      url: urlController.text.isNotEmpty
                          ? urlController.text
                          : null,
                      accountDetails: accountController.text.isNotEmpty
                          ? accountController.text
                          : null,
                      color: selectedColor,
                      features: featuresController.text.isNotEmpty
                          ? featuresController.text
                                .split(',')
                                .map((s) => s.trim())
                                .toList()
                          : <String>[],
                      branchId: selectedBranchId,
                    );

                    setState(() {
                      if (index != null) {
                        _givingMethods[index] = newMethod;
                      } else {
                        _givingMethods.add(newMethod);
                      }
                    });

                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // close manage dialog
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteGivingMethod(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Giving Method'),
          content: Text(
            'Are you sure you want to delete "${_givingMethods[index].title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _givingMethods.removeAt(index);
                });
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // close manage dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showIconPicker(
    StateSetter setDialogState,
    Function(IconData) onIconSelected,
  ) {
    final icons = [
      Icons.credit_card,
      Icons.phone_android,
      Icons.money,
      Icons.currency_bitcoin,
      Icons.account_balance,
      Icons.payment,
      Icons.payments,
      Icons.attach_money,
      Icons.account_circle,
      Icons.link,
      Icons.local_atm,
      Icons.account_balance_wallet,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Icon'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: icons.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    onIconSelected(icons[index]);
                    setDialogState(() {});
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icons[index], size: 32),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showColorPicker(
    StateSetter setDialogState,
    Function(Color) onColorSelected,
  ) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
      Colors.lime,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Color'),
          content: SizedBox(
            width: double.maxFinite,
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    onColorSelected(colors[index]);
                    setDialogState(() {});
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors[index],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class GivingMethod {
  final String title;
  final String description;
  final IconData icon;
  final String? url;
  final String? accountDetails;
  final Color color;
  final List<String> features;
  final int? branchId; // null means global/all branches

  GivingMethod({
    required this.title,
    required this.description,
    required this.icon,
    this.url,
    this.accountDetails,
    required this.color,
    required this.features,
    this.branchId,
  });
}

class GivingCategory {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int percentage;

  GivingCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.percentage,
  });
}
