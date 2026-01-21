import React, { useState, useEffect } from 'react';

// ============================================================
// CHEER SCORESHEET ENTRY FORM
// United Scoring System 2025-2026
// 
// This component creates an interactive scoresheet that:
// - Mirrors the official United rubric layout
// - Auto-calculates section and total scores
// - Validates inputs against scoring rules
// - Exports data ready for your Supabase database
// ============================================================

export default function ScoresheetForm() {
  // ============================================================
  // STATE: All the score fields organized by judge panel
  // ============================================================
  
  // Team & Competition Info
  const [teamInfo, setTeamInfo] = useState({
    teamName: '',
    programName: '',
    level: 'L2',
    ageDivision: 'senior',
    tier: 'elite',
    athleteCount: 20,
    competitionName: '',
    round: 'day1',
  });

  // Building Judge Scores
  const [building, setBuilding] = useState({
    stuntDifficulty: 3.0,
    stuntExecution: 4.0,
    stuntDriverDegree: 0,
    stuntDriverMaxPart: 0,
    pyramidDifficulty: 2.5,
    pyramidExecution: 4.0,
    pyramidDrivers: 0,
    tossDifficulty: 1.0,
    tossExecution: 2.0,
    creativity: 1.75,
    showmanship: 1.5,
  });

  // Tumbling Judge Scores
  const [tumbling, setTumbling] = useState({
    standingDifficulty: 1.5,
    standingExecution: 4.0,
    standingDrivers: 0,
    runningDifficulty: 1.5,
    runningExecution: 4.0,
    runningDrivers: 0,
    jumpsDifficulty: 1.0,
    jumpsExecution: 2.0,
    creativity: 1.75,
    showmanship: 1.5,
  });

  // Overall Judge Scores
  const [overall, setOverall] = useState({
    danceDifficulty: 0.75,
    danceExecution: 0.75,
    formations: 2.0,
    creativity: 1.75,
    showmanship: 1.5,
  });

  // Deductions
  const [deductions, setDeductions] = useState({
    athleteFall: 0,
    majorAthleteFall: 0,
    buildingBobble: 0,
    buildingFall: 0,
    majorBuildingFall: 0,
    boundaryViolation: 0,
    timeLimitViolation: 0,
  });

  // Calculated totals
  const [totals, setTotals] = useState({
    stuntTotal: 0,
    pyramidTotal: 0,
    tossTotal: 0,
    standingTotal: 0,
    runningTotal: 0,
    jumpsTotal: 0,
    danceTotal: 0,
    creativityAvg: 0,
    showmanshipAvg: 0,
    rawScore: 0,
    totalDeductions: 0,
    finalScore: 0,
  });

  // ============================================================
  // AUTO-CALCULATE: Recalculate totals whenever scores change
  // ============================================================
  
  useEffect(() => {
    // Building totals
    const stuntTotal = building.stuntDifficulty + building.stuntExecution + 
                       building.stuntDriverDegree + building.stuntDriverMaxPart;
    const pyramidTotal = building.pyramidDifficulty + building.pyramidExecution + 
                         building.pyramidDrivers;
    const tossTotal = building.tossDifficulty + building.tossExecution;
    
    // Tumbling totals
    const standingTotal = tumbling.standingDifficulty + tumbling.standingExecution + 
                          tumbling.standingDrivers;
    const runningTotal = tumbling.runningDifficulty + tumbling.runningExecution + 
                         tumbling.runningDrivers;
    const jumpsTotal = tumbling.jumpsDifficulty + tumbling.jumpsExecution;
    
    // Overall totals
    const danceTotal = overall.danceDifficulty + overall.danceExecution;
    
    // Averaged scores (3 judges)
    const creativityAvg = (building.creativity + tumbling.creativity + overall.creativity) / 3;
    const showmanshipAvg = (building.showmanship + tumbling.showmanship + overall.showmanship) / 3;
    
    // Deduction calculations
    const totalDeductions = 
      (deductions.athleteFall * 0.15) +
      (deductions.majorAthleteFall * 0.25) +
      (deductions.buildingBobble * 0.25) +
      (deductions.buildingFall * 0.75) +
      (deductions.majorBuildingFall * 1.25) +
      (deductions.boundaryViolation * 0.05) +
      (deductions.timeLimitViolation * 0.05);
    
    // Raw score (all categories)
    const rawScore = stuntTotal + pyramidTotal + tossTotal + 
                     standingTotal + runningTotal + jumpsTotal +
                     danceTotal + overall.formations + 
                     creativityAvg + showmanshipAvg;
    
    const finalScore = rawScore - totalDeductions;
    
    setTotals({
      stuntTotal: round2(stuntTotal),
      pyramidTotal: round2(pyramidTotal),
      tossTotal: round2(tossTotal),
      standingTotal: round2(standingTotal),
      runningTotal: round2(runningTotal),
      jumpsTotal: round2(jumpsTotal),
      danceTotal: round2(danceTotal),
      creativityAvg: round2(creativityAvg),
      showmanshipAvg: round2(showmanshipAvg),
      rawScore: round2(rawScore),
      totalDeductions: round2(totalDeductions),
      finalScore: round2(finalScore),
    });
  }, [building, tumbling, overall, deductions]);

  // Helper to round to 2 decimal places
  const round2 = (num) => Math.round(num * 100) / 100;

  // ============================================================
  // QUANTITY CHART: Calculate based on athlete count
  // ============================================================
  
  const getQuantityChart = (count) => {
    if (count >= 31) return { majority: 5, most: 6, max: 7 };
    if (count >= 23) return { majority: 4, most: 5, max: 6 };
    if (count >= 18) return { majority: 3, most: 4, max: 5 };
    if (count >= 12) return { majority: 2, most: 3, max: 4 };
    return { majority: 1, most: 2, max: 3 };
  };

  const quantityChart = getQuantityChart(teamInfo.athleteCount);

  // ============================================================
  // EXPORT: Format data for database insertion
  // ============================================================
  
  const exportForDatabase = () => {
    const data = {
      team_info: {
        name: teamInfo.teamName,
        program: teamInfo.programName,
        level: teamInfo.level,
        age_division: teamInfo.ageDivision,
        tier: teamInfo.tier,
        athlete_count: teamInfo.athleteCount,
      },
      performance: {
        competition_name: teamInfo.competitionName,
        round: teamInfo.round,
        raw_score: totals.rawScore,
        total_deductions: totals.totalDeductions,
        final_score: totals.finalScore,
      },
      scores_building: {
        stunt_difficulty: building.stuntDifficulty,
        stunt_execution: building.stuntExecution,
        stunt_driver_degree: building.stuntDriverDegree,
        stunt_driver_max_part: building.stuntDriverMaxPart,
        pyramid_difficulty: building.pyramidDifficulty,
        pyramid_execution: building.pyramidExecution,
        pyramid_drivers: building.pyramidDrivers,
        toss_difficulty: building.tossDifficulty,
        toss_execution: building.tossExecution,
        creativity_score: building.creativity,
        showmanship_score: building.showmanship,
      },
      scores_tumbling: {
        standing_difficulty: tumbling.standingDifficulty,
        standing_execution: tumbling.standingExecution,
        standing_drivers: tumbling.standingDrivers,
        running_difficulty: tumbling.runningDifficulty,
        running_execution: tumbling.runningExecution,
        running_drivers: tumbling.runningDrivers,
        jumps_difficulty: tumbling.jumpsDifficulty,
        jumps_execution: tumbling.jumpsExecution,
        creativity_score: tumbling.creativity,
        showmanship_score: tumbling.showmanship,
      },
      scores_overall: {
        dance_difficulty: overall.danceDifficulty,
        dance_execution: overall.danceExecution,
        formations_score: overall.formations,
        creativity_score: overall.creativity,
        showmanship_score: overall.showmanship,
      },
      deductions: Object.entries(deductions)
        .filter(([_, count]) => count > 0)
        .map(([type, count]) => ({
          category: type.replace(/([A-Z])/g, '_$1').toLowerCase(),
          count: count,
        })),
    };
    
    console.log('Export data:', JSON.stringify(data, null, 2));
    alert('Data exported to console! Check browser dev tools.');
    return data;
  };

  // ============================================================
  // REUSABLE COMPONENTS
  // ============================================================

  // Score input with label and validation
  const ScoreInput = ({ label, value, onChange, min, max, step = 0.1, suffix = '' }) => (
    <div className="flex items-center justify-between gap-2 py-1">
      <label className="text-sm text-gray-300 flex-1">{label}</label>
      <div className="flex items-center gap-1">
        <input
          type="number"
          value={value}
          onChange={(e) => onChange(parseFloat(e.target.value) || 0)}
          min={min}
          max={max}
          step={step}
          className="w-16 px-2 py-1 bg-gray-800 border border-gray-600 rounded text-center text-white text-sm focus:border-cyan-400 focus:outline-none"
        />
        {suffix && <span className="text-xs text-gray-500">{suffix}</span>}
      </div>
    </div>
  );

  // Section total display
  const SectionTotal = ({ label, value, max }) => (
    <div className="flex items-center justify-between bg-gray-800/50 px-3 py-2 rounded mt-2">
      <span className="text-sm font-medium text-gray-300">{label}</span>
      <span className="text-lg font-bold text-cyan-400">
        {value} <span className="text-xs text-gray-500">/ {max}</span>
      </span>
    </div>
  );

  // Deduction counter
  const DeductionCounter = ({ label, value, onChange, pointsPer }) => (
    <div className="flex items-center justify-between py-2 border-b border-gray-700/50">
      <div>
        <div className="text-sm text-gray-300">{label}</div>
        <div className="text-xs text-red-400">-{pointsPer} each</div>
      </div>
      <div className="flex items-center gap-2">
        <button
          onClick={() => onChange(Math.max(0, value - 1))}
          className="w-8 h-8 rounded bg-gray-700 hover:bg-gray-600 text-white font-bold"
        >
          -
        </button>
        <span className="w-8 text-center text-white font-bold">{value}</span>
        <button
          onClick={() => onChange(value + 1)}
          className="w-8 h-8 rounded bg-gray-700 hover:bg-gray-600 text-white font-bold"
        >
          +
        </button>
        {value > 0 && (
          <span className="text-red-400 text-sm w-16 text-right">
            -{round2(value * pointsPer)}
          </span>
        )}
      </div>
    </div>
  );

  // ============================================================
  // MAIN RENDER
  // ============================================================

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 text-white p-4">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="text-center mb-6">
          <h1 className="text-2xl font-bold bg-gradient-to-r from-cyan-400 to-emerald-400 bg-clip-text text-transparent">
            🎀 United Scoresheet Entry
          </h1>
          <p className="text-gray-400 text-sm">2025-2026 Scoring System</p>
        </div>

        {/* Team Info Bar */}
        <div className="bg-gray-800/50 rounded-xl p-4 mb-4 border border-gray-700">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <input
              placeholder="Team Name"
              value={teamInfo.teamName}
              onChange={(e) => setTeamInfo({...teamInfo, teamName: e.target.value})}
              className="px-3 py-2 bg-gray-700 border border-gray-600 rounded text-sm focus:border-cyan-400 focus:outline-none"
            />
            <input
              placeholder="Competition"
              value={teamInfo.competitionName}
              onChange={(e) => setTeamInfo({...teamInfo, competitionName: e.target.value})}
              className="px-3 py-2 bg-gray-700 border border-gray-600 rounded text-sm focus:border-cyan-400 focus:outline-none"
            />
            <select
              value={teamInfo.level}
              onChange={(e) => setTeamInfo({...teamInfo, level: e.target.value})}
              className="px-3 py-2 bg-gray-700 border border-gray-600 rounded text-sm focus:border-cyan-400 focus:outline-none"
            >
              {['L1','L2','L3','L4','L4.2','L5','L6','L7'].map(l => (
                <option key={l} value={l}>{l}</option>
              ))}
            </select>
            <div className="flex items-center gap-2">
              <input
                type="number"
                value={teamInfo.athleteCount}
                onChange={(e) => setTeamInfo({...teamInfo, athleteCount: parseInt(e.target.value) || 0})}
                min={5}
                max={38}
                className="w-16 px-2 py-2 bg-gray-700 border border-gray-600 rounded text-sm text-center focus:border-cyan-400 focus:outline-none"
              />
              <span className="text-xs text-gray-400">
                MAJ:{quantityChart.majority} MOST:{quantityChart.most} MAX:{quantityChart.max}
              </span>
            </div>
          </div>
        </div>

        {/* Main Scoring Grid */}
        <div className="grid md:grid-cols-3 gap-4 mb-4">
          
          {/* BUILDING JUDGE */}
          <div className="bg-gray-800/50 rounded-xl border border-red-500/30 overflow-hidden">
            <div className="bg-red-500/20 px-4 py-2 border-b border-red-500/30">
              <h2 className="font-bold text-red-400">🏗️ BUILDING JUDGE</h2>
            </div>
            <div className="p-4 space-y-4">
              {/* Stunt */}
              <div>
                <h3 className="text-sm font-semibold text-gray-400 mb-2">STUNT</h3>
                <ScoreInput label="Difficulty" value={building.stuntDifficulty} 
                  onChange={(v) => setBuilding({...building, stuntDifficulty: v})} 
                  min={2.5} max={4.5} step={0.5} />
                <ScoreInput label="Execution" value={building.stuntExecution} 
                  onChange={(v) => setBuilding({...building, stuntExecution: v})} 
                  min={0} max={4.0} step={0.1} />
                <ScoreInput label="Driver: Degree" value={building.stuntDriverDegree} 
                  onChange={(v) => setBuilding({...building, stuntDriverDegree: v})} 
                  min={0} max={0.8} step={0.1} />
                <ScoreInput label="Driver: Max Part" value={building.stuntDriverMaxPart} 
                  onChange={(v) => setBuilding({...building, stuntDriverMaxPart: v})} 
                  min={0} max={0.7} step={0.1} />
                <SectionTotal label="Stunt Total" value={totals.stuntTotal} max="10.0" />
              </div>
              
              {/* Pyramid */}
              <div>
                <h3 className="text-sm font-semibold text-gray-400 mb-2">PYRAMID</h3>
                <ScoreInput label="Difficulty" value={building.pyramidDifficulty} 
                  onChange={(v) => setBuilding({...building, pyramidDifficulty: v})} 
                  min={2.0} max={4.0} step={0.5} />
                <ScoreInput label="Execution" value={building.pyramidExecution} 
                  onChange={(v) => setBuilding({...building, pyramidExecution: v})} 
                  min={0} max={4.0} step={0.1} />
                <ScoreInput label="Drivers" value={building.pyramidDrivers} 
                  onChange={(v) => setBuilding({...building, pyramidDrivers: v})} 
                  min={0} max={1.0} step={0.1} />
                <SectionTotal label="Pyramid Total" value={totals.pyramidTotal} max="9.0" />
              </div>
              
              {/* Tosses */}
              <div>
                <h3 className="text-sm font-semibold text-gray-400 mb-2">TOSSES</h3>
                <ScoreInput label="Difficulty" value={building.tossDifficulty} 
                  onChange={(v) => setBuilding({...building, tossDifficulty: v})} 
                  min={1.0} max={2.0} step={0.5} />
                <ScoreInput label="Execution" value={building.tossExecution} 
                  onChange={(v) => setBuilding({...building, tossExecution: v})} 
                  min={0} max={2.0} step={0.1} />
                <SectionTotal label="Toss Total" value={totals.tossTotal} max="4.0" />
              </div>
              
              {/* Building Judge's Creativity/Showmanship */}
              <div className="pt-2 border-t border-gray-700">
                <ScoreInput label="Creativity" value={building.creativity} 
                  onChange={(v) => setBuilding({...building, creativity: v})} 
                  min={1.5} max={2.0} step={0.05} />
                <ScoreInput label="Showmanship" value={building.showmanship} 
                  onChange={(v) => setBuilding({...building, showmanship: v})} 
                  min={1.0} max={2.0} step={0.05} />
              </div>
            </div>
          </div>

          {/* TUMBLING JUDGE */}
          <div className="bg-gray-800/50 rounded-xl border border-teal-500/30 overflow-hidden">
            <div className="bg-teal-500/20 px-4 py-2 border-b border-teal-500/30">
              <h2 className="font-bold text-teal-400">🤸 TUMBLING JUDGE</h2>
            </div>
            <div className="p-4 space-y-4">
              {/* Standing */}
              <div>
                <h3 className="text-sm font-semibold text-gray-400 mb-2">STANDING</h3>
                <ScoreInput label="Difficulty" value={tumbling.standingDifficulty} 
                  onChange={(v) => setTumbling({...tumbling, standingDifficulty: v})} 
                  min={0} max={3.0} step={0.5} />
                <ScoreInput label="Execution" value={tumbling.standingExecution} 
                  onChange={(v) => setTumbling({...tumbling, standingExecution: v})} 
                  min={0} max={4.0} step={0.1} />
                <ScoreInput label="Drivers" value={tumbling.standingDrivers} 
                  onChange={(v) => setTumbling({...tumbling, standingDrivers: v})} 
                  min={0} max={1.0} step={0.1} />
                <SectionTotal label="Standing Total" value={totals.standingTotal} max="8.0" />
              </div>
              
              {/* Running */}
              <div>
                <h3 className="text-sm font-semibold text-gray-400 mb-2">RUNNING</h3>
                <ScoreInput label="Difficulty" value={tumbling.runningDifficulty} 
                  onChange={(v) => setTumbling({...tumbling, runningDifficulty: v})} 
                  min={0} max={3.0} step={0.5} />
                <ScoreInput label="Execution" value={tumbling.runningExecution} 
                  onChange={(v) => setTumbling({...tumbling, runningExecution: v})} 
                  min={0} max={4.0} step={0.1} />
                <ScoreInput label="Drivers" value={tumbling.runningDrivers} 
                  onChange={(v) => setTumbling({...tumbling, runningDrivers: v})} 
                  min={0} max={1.0} step={0.1} />
                <SectionTotal label="Running Total" value={totals.runningTotal} max="8.0" />
              </div>
              
              {/* Jumps */}
              <div>
                <h3 className="text-sm font-semibold text-gray-400 mb-2">JUMPS</h3>
                <ScoreInput label="Difficulty" value={tumbling.jumpsDifficulty} 
                  onChange={(v) => setTumbling({...tumbling, jumpsDifficulty: v})} 
                  min={1.0} max={2.0} step={0.5} />
                <ScoreInput label="Execution" value={tumbling.jumpsExecution} 
                  onChange={(v) => setTumbling({...tumbling, jumpsExecution: v})} 
                  min={0} max={2.0} step={0.1} />
                <SectionTotal label="Jumps Total" value={totals.jumpsTotal} max="4.0" />
              </div>
              
              {/* Tumbling Judge's Creativity/Showmanship */}
              <div className="pt-2 border-t border-gray-700">
                <ScoreInput label="Creativity" value={tumbling.creativity} 
                  onChange={(v) => setTumbling({...tumbling, creativity: v})} 
                  min={1.5} max={2.0} step={0.05} />
                <ScoreInput label="Showmanship" value={tumbling.showmanship} 
                  onChange={(v) => setTumbling({...tumbling, showmanship: v})} 
                  min={1.0} max={2.0} step={0.05} />
              </div>
            </div>
          </div>

          {/* OVERALL JUDGE */}
          <div className="bg-gray-800/50 rounded-xl border border-yellow-500/30 overflow-hidden">
            <div className="bg-yellow-500/20 px-4 py-2 border-b border-yellow-500/30">
              <h2 className="font-bold text-yellow-400">🎯 OVERALL JUDGE</h2>
            </div>
            <div className="p-4 space-y-4">
              {/* Dance */}
              <div>
                <h3 className="text-sm font-semibold text-gray-400 mb-2">DANCE</h3>
                <ScoreInput label="Difficulty" value={overall.danceDifficulty} 
                  onChange={(v) => setOverall({...overall, danceDifficulty: v})} 
                  min={0.5} max={1.0} step={0.05} />
                <ScoreInput label="Execution" value={overall.danceExecution} 
                  onChange={(v) => setOverall({...overall, danceExecution: v})} 
                  min={0.5} max={1.0} step={0.05} />
                <SectionTotal label="Dance Total" value={totals.danceTotal} max="2.0" />
              </div>
              
              {/* Formations */}
              <div>
                <h3 className="text-sm font-semibold text-gray-400 mb-2">FORMATIONS & TRANSITIONS</h3>
                <ScoreInput label="Score" value={overall.formations} 
                  onChange={(v) => setOverall({...overall, formations: v})} 
                  min={1.0} max={2.0} step={0.1} />
                <SectionTotal label="Formations" value={overall.formations} max="2.0" />
              </div>
              
              {/* Overall Judge's Creativity/Showmanship */}
              <div className="pt-2 border-t border-gray-700">
                <ScoreInput label="Creativity" value={overall.creativity} 
                  onChange={(v) => setOverall({...overall, creativity: v})} 
                  min={1.5} max={2.0} step={0.05} />
                <ScoreInput label="Showmanship" value={overall.showmanship} 
                  onChange={(v) => setOverall({...overall, showmanship: v})} 
                  min={1.0} max={2.0} step={0.05} />
              </div>
              
              {/* Averaged Scores Display */}
              <div className="pt-4 border-t border-gray-700">
                <h3 className="text-sm font-semibold text-purple-400 mb-2">⭐ AVERAGED (3 Judges)</h3>
                <div className="flex justify-between py-1">
                  <span className="text-sm text-gray-400">Creativity Avg</span>
                  <span className="text-purple-400 font-bold">{totals.creativityAvg}</span>
                </div>
                <div className="flex justify-between py-1">
                  <span className="text-sm text-gray-400">Showmanship Avg</span>
                  <span className="text-purple-400 font-bold">{totals.showmanshipAvg}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Deductions Section */}
        <div className="bg-gray-800/50 rounded-xl border border-red-500/30 p-4 mb-4">
          <h2 className="font-bold text-red-400 mb-4">⚠️ DEDUCTIONS</h2>
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div>
              <DeductionCounter label="Athlete Fall" value={deductions.athleteFall} 
                onChange={(v) => setDeductions({...deductions, athleteFall: v})} pointsPer={0.15} />
              <DeductionCounter label="Major Athlete Fall" value={deductions.majorAthleteFall} 
                onChange={(v) => setDeductions({...deductions, majorAthleteFall: v})} pointsPer={0.25} />
            </div>
            <div>
              <DeductionCounter label="Building Bobble" value={deductions.buildingBobble} 
                onChange={(v) => setDeductions({...deductions, buildingBobble: v})} pointsPer={0.25} />
              <DeductionCounter label="Building Fall" value={deductions.buildingFall} 
                onChange={(v) => setDeductions({...deductions, buildingFall: v})} pointsPer={0.75} />
            </div>
            <div>
              <DeductionCounter label="Major Building Fall" value={deductions.majorBuildingFall} 
                onChange={(v) => setDeductions({...deductions, majorBuildingFall: v})} pointsPer={1.25} />
              <DeductionCounter label="Boundary Violation" value={deductions.boundaryViolation} 
                onChange={(v) => setDeductions({...deductions, boundaryViolation: v})} pointsPer={0.05} />
            </div>
            <div>
              <DeductionCounter label="Time Limit Violation" value={deductions.timeLimitViolation} 
                onChange={(v) => setDeductions({...deductions, timeLimitViolation: v})} pointsPer={0.05} />
            </div>
          </div>
        </div>

        {/* Final Score Summary */}
        <div className="bg-gradient-to-r from-cyan-500/20 to-emerald-500/20 rounded-xl border border-cyan-500/30 p-6">
          <div className="grid md:grid-cols-4 gap-4 text-center">
            <div>
              <div className="text-gray-400 text-sm">Building Total</div>
              <div className="text-2xl font-bold text-red-400">
                {round2(totals.stuntTotal + totals.pyramidTotal + totals.tossTotal)}
              </div>
              <div className="text-xs text-gray-500">/ 23.0</div>
            </div>
            <div>
              <div className="text-gray-400 text-sm">Tumbling Total</div>
              <div className="text-2xl font-bold text-teal-400">
                {round2(totals.standingTotal + totals.runningTotal + totals.jumpsTotal)}
              </div>
              <div className="text-xs text-gray-500">/ 20.0</div>
            </div>
            <div>
              <div className="text-gray-400 text-sm">Overall Total</div>
              <div className="text-2xl font-bold text-yellow-400">
                {round2(totals.danceTotal + overall.formations + totals.creativityAvg + totals.showmanshipAvg)}
              </div>
              <div className="text-xs text-gray-500">/ 8.0</div>
            </div>
            <div>
              <div className="text-gray-400 text-sm">Deductions</div>
              <div className="text-2xl font-bold text-red-400">
                -{totals.totalDeductions}
              </div>
            </div>
          </div>
          
          <div className="mt-6 pt-4 border-t border-gray-700 flex items-center justify-between">
            <div>
              <div className="text-gray-400 text-sm">Raw Score</div>
              <div className="text-xl font-bold text-gray-300">{totals.rawScore}</div>
            </div>
            <div className="text-center">
              <div className="text-gray-400 text-sm">FINAL SCORE</div>
              <div className="text-5xl font-bold bg-gradient-to-r from-cyan-400 to-emerald-400 bg-clip-text text-transparent">
                {totals.finalScore}
              </div>
            </div>
            <button
              onClick={exportForDatabase}
              className="px-6 py-3 bg-gradient-to-r from-cyan-500 to-emerald-500 rounded-lg font-bold hover:opacity-90 transition-opacity"
            >
              Export Data
            </button>
          </div>
        </div>

        {/* Quick Reference */}
        <div className="mt-4 text-center text-xs text-gray-500">
          Quantity Chart: {teamInfo.athleteCount} athletes → 
          MAJORITY: {quantityChart.majority} groups | 
          MOST: {quantityChart.most} groups | 
          MAX: {quantityChart.max} groups
        </div>
      </div>
    </div>
  );
}
