<template>
    <table class="forest-table">
        <thead>
            <tr>
                <th v-if="isVisible('place')" class="sortable" @click="orderTable('place')">Locul</th>
                <th v-if="isVisible('full_name')" class="sortable" @click="orderTable('full_name')">Sportiv</th>
                <th v-if="isVisible('club_name')" class="sortable" @click="orderTable('club_name')">Club</th>
                <th v-if="isVisible('runner_category_name')" class="sortable" @click="orderTable('runner_category_name')">Categoria actuală</th>
                <th v-if="isVisible('time')" class="sortable" @click="orderTable('time')">Timpul</th>
                <th v-if="isVisible('result_category_name')" class="sortable" @click="orderTable('result_category_name')">Categoria îndeplinită</th>
                <th v-if="isVisible('status')" class="sortable" @click="orderTable('status')">Îndeplinire</th>
                <th v-if="isVisible('date')" class="sortable" @click="orderTable('date')">Data</th>
                <th v-if="isVisible('competition_name')" class="sortable" @click="orderTable('competition_name')">Competiția</th>
                <th v-if="isVisible('group_name')" class="sortable" @click="orderTable('group_name')">Grupa</th>
                <th v-if="isVisible('wre_points')" class="sortable" @click="orderTable('wre_points')">WRE Puncte</th>
                <th v-if="isVisible('ecn_points')" class="sortable" @click="orderTable('ecn_points')">ECN Puncte</th>
                <th>Acțiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in elements" :key="element.id">
                <td v-if="isVisible('place')">{{ element.place }}</td>
                <td v-if="isVisible('full_name')"><a :href="`/runners/${element.runner_id}`">{{ element.full_name }}</a></td>
                <td v-if="isVisible('club_name')"><a :href="`/clubs/${element.club_id}`">{{ element.club_name }}</a></td>
                <td v-if="isVisible('runner_category_name')"><a :href="`/categories/${element.runner_category_id}`">{{ element.runner_category_name }}</a></td>
                <td v-if="isVisible('time')">{{ formatResultTime(element.time) }}</td>
                <td v-if="isVisible('result_category_name')"><a :href="`/categories/${element.result_category_id}`">{{ element.result_category_name }}</a></td>
                <td v-if="isVisible('status')" :title="element.status === 'capped' ? 'Sportivul a îndeplinit categorie superioară ce trebuie confirmată în Minister' : null">
                    <a v-if="element.status === 'capped' && element.pending_result_id" :href="`/results/${element.pending_result_id}`" class="cell-badge warning">
                        {{ formatStatus(element.status) }} ({{ element.pending_category_name }})
                    </a>
                    <span v-else class="cell-badge" :class="statusClass(element.status)">{{ formatStatus(element.status) }}</span>
                </td>
                <td v-if="isVisible('date')">{{ element.date }}</td>
                <td v-if="isVisible('competition_name')"><a :href="`/competitions/${element.competition_id}`">{{ element.competition_name }}</a></td>
                <td v-if="isVisible('group_name')"><a :href="`/groups/${element.group_id}`">{{ element.group_name }}</a></td>
                <td v-if="isVisible('wre_points')">{{ element.wre_points }}</td>
                <td v-if="isVisible('ecn_points')">{{ element.ecn_points }}</td>
                <td>
                    <div class="row-actions">
                        <a class="row-action-btn show" :href="`/results/${element.id}`">Arată</a>
                        <button v-if="isAdmin" class="row-action-btn edit" @click="editElement(element)">Editează</button>
                        <button v-if="isAdmin" class="row-action-btn delete" @click="deleteElement(element.id)">Șterge</button>
                    </div>
                </td>
            </tr>
        </tbody>
    </table>
    <Modal ref="modal" :result="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
import { isAdmin } from '@/currentUser'
const props = defineProps({
    elements: Object,
    hiddenColumns: { type: Array, default: () => [] }
})

function isVisible(column) {
    return !props.hiddenColumns.includes(column)
}

const emit = defineEmits(['order', 'refresh'])

const modalElement = ref({})
const modal = ref(null)

function deleteElement(id) {
    if (confirm('Esti sigur ca vrei sa stergi aceast rezultat?')) {
        axios.delete(`/results/${id}`).then(() => {
            emit('refresh')
        })
    }
}

function editElement(element) {
    modalElement.value = {
        ...element,
        time: formatResultTime(element.time)
    }
    modal.value.show()
}

function updateElement(elementData, done) {
    axios.patch(`/results/${elementData.id}.json`, { result: elementData }).then(() => {
        done()
        emit('refresh')
    })
}

function orderTable(sortKey) {
    emit('order', sortKey)
}

function formatResultTime(seconds) {
    if (seconds == null) return ''
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;

    return (
        String(h).padStart(2, '0') + ':' +
        String(m).padStart(2, '0') + ':' +
        String(s).padStart(2, '0')
    );
}

function formatStatus(status) {
    const map = { confirmed: "Îndeplinit", pending: "În așteptare", unconfirmed: "Fără îndeplinire", capped: "Plafonat" }
    return map[status] || status
}

function statusClass(status) {
    const map = { confirmed: "success", pending: "info", unconfirmed: "danger", capped: "warning" }
    return map[status] || ""
}
</script>

<style scoped src="../shared/index.css"></style>
