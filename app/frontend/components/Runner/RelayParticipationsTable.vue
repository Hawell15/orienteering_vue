<template>
    <table class="forest-table">
        <thead>
            <tr>
                <th>Data</th>
                <th>Competiția</th>
                <th>Grupa</th>
                <th>Echipa</th>
                <th>Etapa</th>
                <th>Locul</th>
                <th>Timp echipă</th>
                <th>Timp etapă</th>
                <th>Cat. îndeplinită</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="rp in elements" :key="`${rp.relay_id}-${rp.leg_id}`">
                <td>{{ rp.competition_date }}</td>
                <td><a :href="`/competitions/${rp.competition_id}#${rp.group_name}`">{{ rp.competition_name }}</a></td>
                <td><a :href="`/groups/${rp.group_id}`">{{ rp.group_name }}</a></td>
                <td>{{ rp.team }}</td>
                <td>{{ rp.leg_index }}/{{ rp.leg_count }}</td>
                <td>{{ rp.place || '—' }}</td>
                <td>{{ formatTime(rp.relay_time) }}</td>
                <td>{{ formatTime(rp.leg_time) }}</td>
                <td>{{ rp.relay_category_name || 'f/c' }}</td>
            </tr>
        </tbody>
    </table>
</template>

<script setup>
defineProps({
    elements: { type: Array, default: () => [] }
})

function formatTime(seconds) {
    if (seconds == null) return '—'
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    const s = seconds % 60
    return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0')
}
</script>

<style scoped src="../shared/index.css"></style>
