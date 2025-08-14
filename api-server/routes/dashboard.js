const express = require('express');
// Use app.get('dbService') instead of direct import
// const dbService = require('../config/database');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// Get dashboard statistics for a citizen
router.get('/stats/:citizen_id', authMiddleware, async (req, res) => {
  try {
    const citizen_id = parseInt(req.params.citizen_id);
    
    // Verify user can only access their own stats
    if (citizen_id !== req.user.citizen_id) {
      return res.status(403).json({
        error: 'Access denied',
        message: 'You can only access your own statistics'
      });
    }

    // Get grievance statistics
    const statsResult = await dbService.executeQuery(`
      SELECT 
        COUNT(*) as total_grievances,
        SUM(CASE WHEN status = 'Submitted' THEN 1 ELSE 0 END) as submitted,
        SUM(CASE WHEN status = 'Under Review' THEN 1 ELSE 0 END) as under_review,
        SUM(CASE WHEN status = 'In Progress' THEN 1 ELSE 0 END) as in_progress,
        SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END) as resolved,
        SUM(CASE WHEN status = 'Closed' THEN 1 ELSE 0 END) as closed,
        SUM(CASE WHEN status = 'Rejected' THEN 1 ELSE 0 END) as rejected,
        SUM(CASE WHEN priority = 'Critical' THEN 1 ELSE 0 END) as critical_priority,
        SUM(CASE WHEN priority = 'High' THEN 1 ELSE 0 END) as high_priority,
        SUM(CASE WHEN urgency = 'Emergency' THEN 1 ELSE 0 END) as emergency_urgency
      FROM Grievances 
      WHERE citizen_id = @citizen_id
    `, { citizen_id });

    // Get recent grievances
    const recentResult = await dbService.executeQuery(`
      SELECT TOP 5
        g.grievance_id,
        g.grievance_number,
        g.title,
        g.status,
        g.priority,
        g.submitted_at,
        c.category_name
      FROM Grievances g
      INNER JOIN Categories c ON g.category_id = c.category_id
      WHERE g.citizen_id = @citizen_id
      ORDER BY g.submitted_at DESC
    `, { citizen_id });

    // Get category-wise breakdown
    const categoryResult = await dbService.executeQuery(`
      SELECT 
        c.category_name,
        COUNT(g.grievance_id) as count
      FROM Categories c
      LEFT JOIN Grievances g ON c.category_id = g.category_id AND g.citizen_id = @citizen_id
      WHERE c.is_active = 1
      GROUP BY c.category_id, c.category_name
      ORDER BY count DESC, c.category_name
    `, { citizen_id });

    // Get monthly trends (last 6 months)
    const trendsResult = await dbService.executeQuery(`
      SELECT 
        FORMAT(submitted_at, 'yyyy-MM') as month,
        COUNT(*) as count
      FROM Grievances
      WHERE citizen_id = @citizen_id 
        AND submitted_at >= DATEADD(month, -6, GETDATE())
      GROUP BY FORMAT(submitted_at, 'yyyy-MM')
      ORDER BY month
    `, { citizen_id });

    const stats = statsResult.recordset[0];

    res.json({
      success: true,
      stats: {
        overview: {
          total_grievances: stats.total_grievances,
          pending: stats.submitted + stats.under_review + stats.in_progress,
          resolved: stats.resolved,
          closed: stats.closed,
          rejected: stats.rejected
        },
        status_breakdown: {
          submitted: stats.submitted,
          under_review: stats.under_review,
          in_progress: stats.in_progress,
          resolved: stats.resolved,
          closed: stats.closed,
          rejected: stats.rejected
        },
        priority_breakdown: {
          critical: stats.critical_priority,
          high: stats.high_priority,
          emergency: stats.emergency_urgency
        },
        recent_grievances: recentResult.recordset,
        category_breakdown: categoryResult.recordset,
        monthly_trends: trendsResult.recordset
      }
    });

  } catch (error) {
    console.error('Dashboard stats error:', error);
    res.status(500).json({
      error: 'Stats fetch failed',
      message: error.message
    });
  }
});

// Get system-wide statistics (for admin dashboard - future use)
router.get('/admin/stats', authMiddleware, async (req, res) => {
  try {
    // This would require admin role check in future
    
    const systemStats = await dbService.executeQuery(`
      SELECT 
        COUNT(DISTINCT c.citizen_id) as total_citizens,
        COUNT(g.grievance_id) as total_grievances,
        COUNT(CASE WHEN g.status IN ('Submitted', 'Under Review', 'In Progress') THEN 1 END) as pending_grievances,
        COUNT(CASE WHEN g.status = 'Resolved' THEN 1 END) as resolved_grievances,
        AVG(DATEDIFF(day, g.submitted_at, COALESCE(g.resolved_at, GETDATE()))) as avg_resolution_days
      FROM Citizens c
      LEFT JOIN Grievances g ON c.citizen_id = g.citizen_id
      WHERE c.is_active = 1
    `);

    // Top categories
    const topCategories = await dbService.executeQuery(`
      SELECT TOP 5
        cat.category_name,
        COUNT(g.grievance_id) as grievance_count
      FROM Categories cat
      LEFT JOIN Grievances g ON cat.category_id = g.category_id
      WHERE cat.is_active = 1
      GROUP BY cat.category_id, cat.category_name
      ORDER BY grievance_count DESC
    `);

    // Recent activity
    const recentActivity = await dbService.executeQuery(`
      SELECT TOP 10
        g.grievance_number,
        g.title,
        g.status,
        g.submitted_at,
        c.full_name as citizen_name,
        cat.category_name
      FROM Grievances g
      INNER JOIN Citizens c ON g.citizen_id = c.citizen_id
      INNER JOIN Categories cat ON g.category_id = cat.category_id
      ORDER BY g.submitted_at DESC
    `);

    res.json({
      success: true,
      system_stats: systemStats.recordset[0],
      top_categories: topCategories.recordset,
      recent_activity: recentActivity.recordset
    });

  } catch (error) {
    console.error('Admin dashboard stats error:', error);
    res.status(500).json({
      error: 'Stats fetch failed',
      message: error.message
    });
  }
});

module.exports = router;
