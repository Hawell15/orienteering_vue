<template>
    <table class="forest-table">
        <thead>
            <tr>
                <th class="sortable" @click="orderTable('id')">ID</th>
                <th class="sortable" @click="orderTable('group_name')">Grupa</th>
                <th class="sortable" @click="orderTable('competition_name')">Competiția</th>
                <th class="sortable" @click="orderTable('date')">Data</th>
                <th class="sortable" @click="orderTable('rang')">Rang</th>
                <th class="sortable" @click="orderTable('clasa')">Clasa</th>
                <th class="sortable" @click="orderTable('ecn_coeficient')">Coef. ECN</th>
                <th class="sortable" @click="orderTable('results_count')">Rezultate</th>
                <th>Acțiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in elements" :key="element.id">
                <td><a :href="`/groups/${element.id}`">{{ element.id }}</a></td>
                <td><a :href="`/groups/${element.id}`">{{ element.group_name }}</a></td>
                <td><a :href="`/competitions/${element.competition_id}`">{{ element.competition_name }}</a></td>
                <td>{{ element.date }}</td>
                <td>{{ element.rang }}</td>
                <td>
                    <span v-if="element.clasa_name" class="cell-badge">{{ element.clasa_name }}</span>
                    <span v-else class="cell-no">—</span>
                </td>
                <td>
                    <span v-if="element.ecn_coeficient" class="cell-badge ecn">{{ element.ecn_coeficient }}</span>
                    <span v-else class="cell-no">—</span>
                </td>
                <td><a :href="`/results?group_id=${element.id}`">{{ element.results_count }}</a></td>
                <td>
                    <div class="row-actions">
                        <a class="row-action-btn show" :href="`/groups/${element.id}`">Arată</a>
                        <button class="row-action-btn edit" @click="editElement(element)">Editează</button>
                        <button class="row-action-btn delete" @click="deleteElement(element.id)">Șterge</button>
                    </div>
                </td>
            </tr>
        </tbody>
    </table>
    <Modal ref="modal" :group="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
const props = defineProps({
    elements: Object
})

const emit = defineEmits(['order'])

const modalElement = ref({})
const modal = ref(null)

function deleteElement(id) {
    if (confirm('Esti sigur ca vrei sa stergi această grupă?')) {
        axios.delete(`/groups/${id}`).then(() => {
            props.elements = props.elements.filter(group => group.id !== id)
        })
    }
}

function editElement(element) {
    modalElement.value = { ...element }
    modal.value.show()
}

function updateElement(elementData, done) {
    axios.patch(`/groups/${elementData.id}.json`, { group: elementData }).then(res => {
        const index = props.elements.findIndex(c => c.id === res.data.id)
        if (index !== -1) props.elements[index] = { ...props.elements[index], ...res.data }
        done()
    })
}

function orderTable(sortKey) {
    emit('order', sortKey)
}
</script>

<style scoped src="../shared/index.css"></style>
